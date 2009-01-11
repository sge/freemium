module Freemium
  module SubscriptionCoupon
    
    def self.included(base)
      base.class_eval do
        belongs_to :subscription
        belongs_to :coupon
        
        before_create :set_redeemed_on
        
        validates_presence_of :coupon
        validates_uniqueness_of :coupon_id, :scope => :subscription_id, :message => "has already been applied"   
      end
    end

    def destroy
      self.update_attribute :deleted_at, Time.now
    end  
    
    def active?
      expires_on ? Date.today <= self.expires_on : true
    end
    
    def expires_on
      return nil unless self.coupon.duration_in_months
      self.redeemed_on + self.coupon.duration_in_months.months
    end
    
    protected
    
    def set_redeemed_on
      self.redeemed_on = Date.today
    end
    
    def validate_on_create
      errors.add :subscription,  "must be paid"       if self.subscription && !self.subscription.paid?
      errors.add :coupon,  "has expired"              if self.coupon && (self.coupon.expired? || self.coupon.expired?)   
    end    
              
  end
end