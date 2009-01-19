module Freemium
  # adds manual billing functionality to the Subscription class
  module ManualBilling
    def self.included(base)
      base.extend ClassMethods
    end

    # charges this subscription.
    # assumes, of course, that this module is mixed in to the Subscription model
    def charge!
      self.class.transaction do
        # attempt to bill (use gateway)
        @transaction = Freemium.gateway.charge(billing_key, self.rate)
        self.transactions << @transaction
        @transaction.success? ? receive_payment!(@transaction.amount, transaction) : expire_after_grace!(@transaction)
        @transaction
      end
    end

    module ClassMethods
      # the process you should run periodically
      def run_billing
        # charge all billable subscriptions
        @transactions = find_billable.collect{|b| b.charge!}
        # actually expire any subscriptions whose time has come
        expire

        # send the activity report
        Freemium.mailer.deliver_admin_report(
          @transactions # Add in transactions
        ) if Freemium.admin_report_recipients
        
        @transactions
      end

      protected

      # a subscription is due on the last day it's paid through. so this finds all
      # subscriptions that expire the day *after* the given date. note that this
      # also finds past-due subscriptions, as long as they haven't been set to
      # expire.
      # because of coupons we can't trust rate_cents alone and need to verify that the account is indeed paid?
      def find_billable(date = Date.today)
        find(
          :all,
          :include => [:subscription_plan],
          :conditions => ['freemium_subscription_plans.rate_cents > 0 AND paid_through <= ? AND (expire_on IS NULL or expire_on < paid_through)', date.to_date]
        ).select{|s| s.paid?}
      end
    end
  end
end