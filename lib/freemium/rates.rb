module Freemium
  module Rates
    
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
      return false unless rate
      rate.cents > 0
    end    
    
  end
end