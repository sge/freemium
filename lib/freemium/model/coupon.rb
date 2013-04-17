module Freemium
  module Coupon

    def self.included(base)
      base.class_eval do
        has_many :coupon_redemptions, :dependent => :destroy, :class_name => "CouponRedemption", :foreign_key => :coupon_id
        has_many :subscriptions, :through => :coupon_redemptions
        has_and_belongs_to_many :subscription_plans, :class_name => "SubscriptionPlan",
          :join_table => :coupons_subscription_plans, :foreign_key => :coupon_id, :association_foreign_key => :subscription_plan_id

        validates_presence_of :description, :discount_percentage
        validates_inclusion_of :discount_percentage, :in => 1..100

        before_save :normalize_redemption_key
      end
    end

    def discount(rate)
      rate * (1 - self.discount_percentage.to_f / 100)
    end

    def expired?
      (self.redemption_expiration && Date.today > self.redemption_expiration) || (self.redemption_limit && self.coupon_redemptions.count >= self.redemption_limit)
    end

    def applies_to_plan?(subscription_plan)
      return true if self.subscription_plans.blank? # applies to all plans
      self.subscription_plans.include?(subscription_plan)
    end

    protected

    def normalize_redemption_key
      self.redemption_key.downcase! unless self.redemption_key.blank?
    end

  end
end
