module Freemium
  # adds recurring billing functionality to the Subscription class
  module RecurringBilling
    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      # the process you should run periodically
      def run_billing
        # first, synchronize transactions
        transactions = process_transactions

        # then, set expiration for any subscriptions that didn't process
        find_expirable.each(&:expire_after_grace!)
        # then, actually expire any subscriptions whose time has come
        expire

        # send the activity report
        Freemium.mailer.deliver_admin_report(
          transactions
        ) if Freemium.admin_report_recipients && !new_transactions.empty?
      end

      protected

      # retrieves all transactions posted after the last known transaction
      #
      # please note how this works: it calculates the maximum last_transaction_at
      # value and only retrieves transactions after that. so be careful that you
      # don't accidentally update the last_transaction_at field for some subset
      # of subscriptions, and leave the others behind!
      def new_transactions
        Freemium.gateway.transactions(:after => self.maximum(:last_transaction_at))
      end

      # updates all subscriptions with any new transactions
      def process_transactions(transactions = new_transactions)
        transaction do
          transactions.each do |t|
            subscription = ::Subscription.find_by_billing_key(t.billing_key)
            subscription.transactions << t
            t.success? ? subscription.receive_payment!(t) : subscription.expire_after_grace!(t)
          end
        end
        transactions
      end

      # finds all subscriptions that should have paid but didn't and need to be expired
      # because of coupons we can't trust rate_cents alone and need to verify that the account is indeed paid?
      def find_expirable
        paid.
          where(['paid_through < ?', Date.today]).
          where('(expire_on IS NULL OR expire_on < paid_through)').
          select { |s| s.paid? }
      end
    end
  end
end
