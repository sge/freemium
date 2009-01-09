# == Attributes
#   subscriptions:      all subscriptions for the plan
#   rate_cents:         how much this plan costs, in cents
#   rate:               how much this plan costs, in Money
#   yearly:             whether this plan cycles yearly or monthly
#
module Freemium
  module SubscriptionPlan
    
    def self.included(base)
      base.class_eval do
        # yes, subscriptions.subscription_plan_id may not be null, but
        # this at least makes the delete not happen if there are any active.
        has_many :subscriptions, :dependent => :nullify
        
        composed_of :rate, :class_name => 'Money', :mapping => [ %w(rate_cents cents) ], :allow_nil => true
        
        validates_presence_of :name
        validates_presence_of :key
        validates_presence_of :rate_cents
        
        before_validation :set_key
      end
    end
    
    # returns the daily cost of this plan.
    def daily_rate
      yearly_rate / 365
    end

    # returns the yearly cost of this plan.
    def yearly_rate
      rate * 12
    end

    # returns the monthly cost of this plan.
    def monthly_rate
      rate
    end
    
    def paid?
      rate_cents > 0
    end    

    def complimentary?
      !self.paid? and self.subscription_plan.paid?
    end

    def discounted?
      self.rate_cents != self.subscription_plan.rate_cents
    end    
    
    protected
    
    def set_key      
      self.key = ActiveSupport::Inflector.underscore(name) unless name.blank?
    end
    
  end
end