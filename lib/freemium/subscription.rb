# == Attributes
#   subscribable:         the model in your system that has the subscription. probably a User.
#   subscription_plan:    which service plan this subscription is for. affects how payment is interpreted.
#   paid_through:         when the subscription currently expires, assuming no further payment. for manual billing, this also determines when the next payment is due.
#   billing_key:          the id for this user in the remote billing gateway. may not exist if user is on a free plan.
#   last_transaction_at:  when the last gateway transaction was for this account. this is used by your gateway to find "new" transactions.
#
module Freemium
  module Subscription
    include Rates
        
    def self.included(base)
      base.class_eval do
        belongs_to :subscription_plan, :class_name => "FreemiumSubscriptionPlan"
        belongs_to :subscribable, :polymorphic => true
        belongs_to :credit_card, :dependent => :destroy, :class_name => "FreemiumCreditCard"
        has_many :coupon_redemptions, :conditions => "expired_on IS NULL", :class_name => "FreemiumCouponRedemption", :foreign_key => :subscription_id
        has_many :coupons, :through => :coupon_redemptions, :conditions => "coupon_redemptions.expired_on IS NULL"
              
        before_validation :set_paid_through
        before_validation :set_started_on
        before_save :store_credit_card_offsite
        before_save :discard_credit_card_unless_paid
        before_destroy :cancel_in_remote_system
        before_save :deactivate_coupons_if_plan_changed
           
        validates_presence_of :subscribable
        validates_associated :subscribable
        validates_presence_of :subscription_plan
        validates_presence_of :paid_through, :if => :paid? 
        validates_presence_of :started_on
        validates_presence_of :credit_card, :if => :paid?
        validates_associated :credit_card, :if => :paid?
      end
      base.extend ClassMethods
    end
    
    ##
    ## Callbacks
    ##
    
    protected

    def set_paid_through
      # no prorations or trial periods when changing plans
      if subscription_plan_id_changed? && !paid_through_changed?
        if paid?
          self.paid_through = Date.today
          self.paid_through += Freemium.days_free_trial if new_record?
        else
          self.paid_through = nil
        end
      end
    end    

    def set_started_on
      self.started_on = Date.today if subscription_plan_id_changed?
    end

    # Simple assignment of a credit card. Note that this may not be
    # useful for your particular situation, especially if you need
    # to simultaneously set up automated recurrences.
    #
    # Because of the third-party interaction with the gateway, you
    # need to be careful to only use this method when you expect to
    # be able to save the record successfully. Otherwise you may end
    # up storing a credit card in the gateway and then losing the key.
    #
    # NOTE: Support for updating an address could easily be added
    # with an "address" property on the credit card.
    def store_credit_card_offsite
      if credit_card && credit_card.changed? && credit_card.valid? 
        response = billing_key ? Freemium.gateway.update(billing_key, credit_card) : Freemium.gateway.store(credit_card)
        raise Freemium::CreditCardStorageError.new(response.message) unless response.success?
        self.billing_key = response.billing_key
        self.expire_on = nil
        self.credit_card.reload # to prevent needless subsequent store() calls
      end
    end
    
    def discard_credit_card_unless_paid
      unless paid?
        credit_card.destroy if credit_card
        cancel_in_remote_system
      end
    end
    
    def cancel_in_remote_system
      if billing_key
        Freemium.gateway.cancel(self.billing_key)
        self.billing_key = nil
      end
    end
    
    # disable coupons when
    def deactivate_coupons_if_plan_changed
      self.coupon_redemptions.each{ |c| c.expire! } if subscription_plan_id_changed? && !new_record?
    end
    
    public
    
    ##
    ## Class Methods
    ##
    
    module ClassMethods
      # expires all subscriptions that have been pastdue for too long (accounting for grace)
      def expire
        find(:all, :conditions => ['expire_on >= paid_through AND expire_on <= ?', Date.today]).select{|s| s.paid?}.each(&:expire!)
      end      
    end
    
    ##
    ## Rate
    ##
    
    def rate
      return nil unless subscription_plan
      rate = self.subscription_plan.rate
      rate = self.coupon.discount(rate) if coupon
      rate
    end
    
    def paid?
      return false unless rate
      rate.cents > 0
    end
    
    ##
    ## Coupon Redemption
    ##
    
    def apply_coupon!(coupon)
      self.coupons << coupon
    end  
      
    def coupon=(coupon)
      s = FreemiumCouponRedemption.new(:subscription => self, :coupon => coupon)
      coupon_redemptions << s
    end
    
    def coupon
      return nil if coupon_redemptions.empty?
      active_coupons = coupon_redemptions.select{|c| c.active?}
      return nil if active_coupons.empty?
      active_coupons.sort_by{|c| c.coupon.discount_percentage }.reverse.first.coupon
    end

    ##
    ## Receiving More Money
    ##

    # receives payment and saves the record
    def receive_payment!(value)
      receive_payment(value)
      save!
    end

    # sends an invoice for the specified amount. note that this is an after-the-fact
    # invoice.
    def send_invoice(amount)
      Freemium.mailer.deliver_invoice(subscribable, self, amount)
    end

    ##
    ## Remaining Time
    ##

    # returns the value of the time between now and paid_through.
    # will optionally interpret the time according to a certain subscription plan.
    def remaining_value(subscription_plan_id = self.subscription_plan_id)
      self.daily_rate * remaining_days
    end

    # if paid through today, returns zero
    def remaining_days
      self.paid_through - Date.today
    end

    ##
    ## Grace Period
    ##

    # if under grace through today, returns zero
    def remaining_days_of_grace
      self.expire_on - Date.today - 1
    end

    def in_grace?
      remaining_days < 0 and not expired?
    end

    ##
    ## Expiration
    ##

    # sets the expiration for the subscription based on today and the configured grace period.
    def expire_after_grace!
      self.expire_on = [Date.today, paid_through].max + Freemium.days_grace
      Freemium.activity_log[self] << "now set to expire on #{self.expire_on}" if Freemium.log?
      Freemium.mailer.deliver_expiration_warning(subscribable, self)
      save!
    end

    # sends an expiration email, then downgrades to a free plan
    def expire!
      Freemium.activity_log[self] << "expired!" if Freemium.log?
      Freemium.mailer.deliver_expiration_notice(subscribable, self)
      # downgrade to a free plan
      self.subscription_plan = Freemium.expired_plan
      # throw away this credit card (they'll have to start all over again)
      self.save!
    end

    def expired?
      expire_on and expire_on <= Date.today
    end

    protected

    # extends the paid_through period according to how much money was received.
    # when possible, avoids the days-per-month problem by checking if the money
    # received is a multiple of the plan's rate.
    #
    # really, i expect the case where the received payment does not match the
    # subscription plan's rate to be very much an edge case.
    def receive_payment(value)
      self.paid_through = if value.cents % rate.cents == 0
        self.paid_through + (value.cents / rate.cents).months
      else
        # edge case
        self.paid_through + (value.cents / daily_rate.cents)
      end
      
      # if they've paid again, then reset expiration
      self.expire_on = nil

      Freemium.activity_log[self] << "now paid through #{self.paid_through}" if Freemium.log?

      send_invoice(value)
    end

  end
end