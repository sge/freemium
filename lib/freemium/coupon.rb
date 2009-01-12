module Freemium
  module Coupon
    
    def self.included(base)
      base.class_eval do
        has_many :coupon_redemptions, :dependent => :destroy
        has_many :subscriptions, :through => :coupon_redemptions
        has_and_belongs_to_many :subscription_plans
        
        validates_presence_of :description, :discount_percentage
        validates_inclusion_of :discount_percentage, :in => 1..100
      end
    end
    
    def expired?
      (self.redemption_expiration && Date.today > self.redemption_expiration) || (self.redemption_limit && self.coupon_redemptions.count >= self.redemption_limit)
    end
    
    def applies_to_plan?(subscription_plan)
      return true if self.subscription_plans.blank? # applies to all plans
      self.subscription_plans.include?(subscription_plan)
    end
        
  end
end