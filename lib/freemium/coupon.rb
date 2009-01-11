module Freemium
  module Coupon
    
    def self.included(base)
      base.class_eval do
        has_many :subscription_coupons, :dependent => :destroy
        
        validates_presence_of :description, :discount_percentage
        validates_inclusion_of :discount_percentage, :in => 1..100
      end
    end
    
    def expired?
      (self.redemption_expiration && Date.today > self.redemption_expiration) || (self.redemption_limit && self.subscription_coupons.count >= self.redemption_limit)
    end
    
    
    # available?
    
    # available_for_plan?
    
    # 
        
  end
end