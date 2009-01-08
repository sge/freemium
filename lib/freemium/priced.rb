module Freemium
  module Priced

    def self.included(base)
      base.class_eval do
        composed_of :rate, :class_name => 'Money', :mapping => [ %w(rate_cents cents) ], :allow_nil => true
        validates_presence_of :rate_cents
      end
    end    

    # returns the daily cost of this plan.
    def daily_rate
      yearly_rate / 365
    end

    # returns the yearly cost of this plan.
    def yearly_rate
      yearly? ? rate : rate * 12
    end

    # returns the monthly cost of this plan.
    def monthly_rate
      yearly? ? rate / 12 : rate
    end
    
    def paid?
      rate_cents > 0
    end
    
  end
end