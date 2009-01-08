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
        include Freemium::Priced
        
        # yes, subscriptions.subscription_plan_id may not be null, but
        # this at least makes the delete not happen if there are any active.
        has_many :subscriptions, :dependent => :nullify
        validates_presence_of :name
      end
    end
    
  end
end