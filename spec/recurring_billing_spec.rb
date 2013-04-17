require 'spec_helper'


describe Subscription do
  fixtures :users, :subscriptions, :subscription_plans, :credit_cards


  before(:each) do
    class Subscription
      include Freemium::RecurringBilling
    end
    Freemium.gateway = Freemium::Gateways::Test.new
  end

  it "should run billing" do
    Subscription.should_receive(:process_transactions).once
    Subscription.should_receive(:find_expirable).once.and_return([])
    Subscription.should_receive(:expire).once
    Subscription.run_billing
  end

  it "should send reports" do
    Subscription.stub!(:process_transactions)
    Freemium.stub!(:admin_report_recipients).and_return("test@example.com")

    Freemium.mailer.should_receive(:deliver_admin_report)
    Subscription.run_billing
  end

  it "should find expireable subscriptions" do
    # making a one-off fixture set, basically
    create_billable_subscription # this subscription qualifies
    create_billable_subscription(:subscription_plan => subscription_plans(:free)) # this subscription would qualify, except it's for the free plan
    create_billable_subscription(:paid_through => Date.today) # this subscription would qualify, except it's already paid
    create_billable_subscription(:coupon => Coupon.create!(:description => "Complimentary", :discount_percentage => 100)) # should NOT be billable because it's free
    s = create_billable_subscription # this subscription would qualify, except it's already been set to expire
    s.update_attribute :expire_on, Date.today + 1

    expirable = Subscription.send(:find_expirable)
    expirable.all? { |subscription| subscription.paid?                              }.should be_true, "free subscriptions don't expire"
    expirable.all? { |subscription| !subscription.in_trial?                         }.should be_true, "subscriptions that have been paid are no longer in the trial period"
    expirable.all? { |subscription| subscription.paid_through < Date.today          }.should be_true, "paid subscriptions don't expire"
    expirable.all? { |subscription|
      !subscription.expire_on or subscription.expire_on < subscription.paid_through }.should be_true, "subscriptions already expiring aren't included"

    expirable.size.should eql(1)
  end

  it "should process new transactions" do
    subscription = subscriptions(:bobs_subscription)
    subscription.coupon = Coupon.create!(:description => "Complimentary", :discount_percentage => 30)
    subscription.save!

    paid_through = subscription.paid_through
    t = AccountTransaction.new(:billing_key => subscription.billing_key, :amount => subscription.rate, :success => true)
    Subscription.stub!(:new_transactions => [t])

    # the actual test
    Subscription.send :process_transactions
    subscription.reload.paid_through.to_s.should eql((paid_through + 1.month).to_s), "extended by two months"
  end

  it "should process a failed transaction" do
    subscription = subscriptions(:bobs_subscription)
    paid_through = subscription.paid_through
    t = AccountTransaction.new(:billing_key => subscription.billing_key, :amount => subscription.rate, :success => false)
    Subscription.stub!(:new_transactions => [t])

    # the actual test
    subscription.expire_on.should be_nil
    Subscription.send :process_transactions
    subscription.reload.paid_through.should eql(paid_through), "not extended"
    subscription.expire_on.should_not be_nil
  end

  it "should find new transactions" do
    last_transaction_at = Subscription.maximum(:last_transaction_at)
    method_args = Subscription.send(:new_transactions)
    method_args[:after].should eql(last_transaction_at)
  end

  protected

  def create_billable_subscription(options = {})
    Subscription.create!({
      :subscription_plan => subscription_plans(:premium),
      :subscribable => User.new(:name => 'a'),
      :paid_through => Date.today - 1,
      :credit_card => CreditCard.sample
    }.merge(options))
  end
end
