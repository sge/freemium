module Freemium
  module SubscriptionChange

    def self.included(base)
      base.class_eval do
        belongs_to :subscribable, :polymorphic => true

        belongs_to :original_subscription_plan, :class_name => "FreemiumSubscriptionPlan"
        belongs_to :new_subscription_plan, :class_name => "FreemiumSubscriptionPlan"

        validates_presence_of :reason
        validates_inclusion_of :reason, :in => %w(new upgrade downgrade expiration cancellation)
      end
    end

  end
end