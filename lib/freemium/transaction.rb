module Freemium
  module Transaction

    def self.included(base)
      base.class_eval do
        scope :since, lambda { |time| where(["created_at >= ?", time]) }

        belongs_to :subscription, :class_name => "Subscription"

        composed_of :amount, :class_name => 'Money', :mapping => [ %w(amount_cents cents) ], :allow_nil => true
      end
    end

  end
end
