module Freemium
  module Transaction

    def self.included(base)
      base.class_eval do
        named_scope :since, lambda { |time| {:conditions => ["created_at >= ?", time]} }
        
        belongs_to :subscription, :class_name => "FreemiumSubscription"
        
        composed_of :amount, :class_name => 'Money', :mapping => [ %w(amount_cents cents) ], :allow_nil => true        
      end
    end

  end
end