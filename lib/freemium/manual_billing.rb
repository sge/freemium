module Freemium
  # adds manual billing functionality to the Subscription class
  module ManualBilling
    def self.included(base)
      base.extend ClassMethods
    end

    # Override if you need to charge something different than the rate (ex: yearly billing option)
    def installment_amount(options = {})
      self.rate(options)
    end

    # charges this subscription.
    # assumes, of course, that this module is mixed in to the Subscription model
    def charge!
      # Save the transaction immediately

      @transaction = gateway.charge(billing_key, self.installment_amount)
      self.transactions << @transaction
      self.last_transaction_at = Time.now # TODO this could probably now be inferred from the list of transactions
      self.last_transaction_success = @transaction.success?

      self.save(:validate => false)

      begin
        if @transaction.success?
          receive_payment!(@transaction)
        elsif !@transaction.subscription.in_grace?
          expire_after_grace!(@transaction)
        end
      rescue
      end

      @transaction
    end

    def store_credit_card_offsite
      if credit_card && credit_card.changed? && credit_card.valid?
        response = billing_key ? gateway.update(billing_key, credit_card, credit_card.address) : gateway.store(credit_card, credit_card.address)
        raise Freemium::CreditCardStorageError.new(response.message) unless response.success?
        self.billing_key = response.billing_key
        self.expire_on = nil if last_transaction_success
        self.credit_card.reload # to prevent needless subsequent store() calls
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
        ) if Freemium.admin_report_recipients && !@transactions.empty?

        @transactions
      end

      protected

      # a subscription is due on the last day it's paid through. so this finds all
      # subscriptions that expire the day *after* the given date.
      # because of coupons we can't trust rate_cents alone and need to verify that the account is indeed paid?
      def find_billable
        self.paid.due.select{|s| s.paid?}
      end
    end
  end
end
