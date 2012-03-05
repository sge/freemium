require 'spec_helper'

describe FreemiumSubscription do
  fixtures :users, :freemium_subscriptions, :freemium_subscription_plans, :freemium_credit_cards


  before(:each) do
    Freemium.gateway = Freemium::Gateways::Test.new
  end

  it "should find billable" do
    # making a one-off fixture set, basically
    create_billable_subscription # this subscription should be billable
    create_billable_subscription(:paid_through => Date.today) # this subscription should be billable
    create_billable_subscription(:coupon => FreemiumCoupon.create!(:description => "Complimentary", :discount_percentage => 100)) # should NOT be billable because it's free
    create_billable_subscription(:subscription_plan => freemium_subscription_plans(:free)) # should NOT be billable because it's free
    create_billable_subscription(:paid_through => Date.today + 1) # should NOT be billable because it's paid far enough out
    s = create_billable_subscription # should be billable because it's past due
    s.update_attribute :expire_on, Date.today + 1

    expirable = FreemiumSubscription.send(:find_billable)
    expirable.all? { |subscription| subscription.paid?                      }.should be_true, "free subscriptions aren't billable"
    expirable.all? { |subscription| !subscription.in_trial?                 }.should be_true, "subscriptions that have been paid are no longer in the trial period"
    expirable.all? { |subscription| subscription.paid_through <= Date.today }.should be_true, "subscriptions paid through tomorrow aren't billable yet"
    expirable.size.should eql(3)

    Freemium.gateway.stub!(:charge).and_return(
      FreemiumTransaction.new(
        :billing_key => s.billing_key,
        :amount => s.rate,
        :success => false
      )
    )

    FreemiumSubscription.run_billing.size.should eql(expirable.size)
  end

  it "should not change expire_on on failure overdue payment" do
    subscription = create_billable_subscription # should NOT be billable because it's already expiring
    expire_on = Date.today + 2
    paid_through = subscription.paid_through
    subscription.update_attribute :expire_on, expire_on
    subscription.reload
    subscription.expire_on.should eql(expire_on)
    expirable = FreemiumSubscription.send(:find_billable)
    expirable.size.should eql(1), "Subscriptions in their grace period should be retried"

    Freemium.gateway.stub!(:charge).and_return(
      FreemiumTransaction.new(
        :billing_key => subscription.billing_key,
        :amount => subscription.rate,
        :success => false
      )
    )

    lambda do
      transaction = subscription.charge!
      subscription.expire_on.should eql(expire_on), "Billing failed on existing overdue account but the expire_on date was changed"
    end.should_not raise_error
  end

  it "should change expire_on on success overdue payment" do
    subscription = create_billable_subscription # should NOT be billable because it's already expiring
    expire_on = Date.today + 2
    paid_through = subscription.paid_through
    subscription.update_attribute :expire_on, expire_on

    expirable = FreemiumSubscription.send(:find_billable)
    expirable.size.should eql(1), "Subscriptions in their grace period should be retried"

    Freemium.gateway.stub!(:charge).and_return(
      FreemiumTransaction.new(
        :billing_key => subscription.billing_key,
        :amount => subscription.rate,
        :success => true
      )
    )

    assert_nothing_raised do
      transaction = subscription.charge!
      transaction.subscription.paid_through.to_s.should eql((paid_through >> 1).to_s), "extended by a month"
      subscription.expire_on.should be_nil, "Billing succeeded on existing overdue account but the expire_on date was not reset"
    end
  end

  it "should charge a subscription" do
    subscription = FreemiumSubscription.first
    subscription.coupon = FreemiumCoupon.create!(:description => "Complimentary", :discount_percentage => 30)
    subscription.save!

    paid_through = subscription.paid_through

    Freemium.gateway.stub!(:charge).and_return(
      FreemiumTransaction.new(
        :billing_key => subscription.billing_key,
        :amount => subscription.rate,
        :success => true
      )
    )

    lambda do
      transaction = subscription.charge!
      transaction.subscription.paid_through.to_s.should eql((paid_through >> 1).to_s)#, "extended by a month"
    end.should_not raise_error

    subscription = subscription.reload
    subscription.transactions.empty?.should be_false
    subscription.transactions.last.should be_true
    subscription.transactions.last.success?.should be_true
    subscription.transactions.last.message?.should_not be_nil
    ((Time.now - 1.minute) < subscription.last_transaction_at).should be_true
    FreemiumTransaction.since(Date.today).empty?.should be_false
    subscription.transactions.last.amount.should eql(subscription.rate)
    subscription.reload.paid_through.to_s.should eql((paid_through >> 1).to_s), "extended by a month"
  end


  it "should charge an aborted subscription" do
    subscription = FreemiumSubscription.first
    subscription.coupon = FreemiumCoupon.create!(:description => "Complimentary", :discount_percentage => 30)
    subscription.save!

    paid_through = subscription.paid_through
    subscription.transactions.empty?.should be_true

    Freemium.gateway.stub!(:charge).and_return(
      FreemiumTransaction.new(
        :billing_key => subscription.billing_key,
        :amount => subscription.rate,
        :success => true
      )
    )

    subscription.should_receive(:receive_payment).and_raise(RuntimeError)
    subscription.charge!
    subscription.reload.transactions.empty?.should be_false
  end

  it "should not charge a subscription" do
    subscription = FreemiumSubscription.first
    paid_through = subscription.paid_through
    Freemium.gateway.stub!(:charge).and_return(
      FreemiumTransaction.new(
        :billing_key => subscription.billing_key,
        :amount => subscription.rate,
        :success => false
      )
    )

    subscription.expire_on.should be_nil
    lambda { subscription.charge! }.should_not raise_error
    subscription.reload.paid_through.should eql(paid_through), "not extended"
    subscription.expire_on.should_not be_nil
    subscription.transactions.last.success?.should be_false
  end

  it "should receive charge! on billable when we run billing" do
    subscription = FreemiumSubscription.first
    FreemiumSubscription.stub!(:find_billable => [subscription])
    subscription.should_receive(:charge!).once
    FreemiumSubscription.send :run_billing
  end

  protected

  def create_billable_subscription(options = {})
    FreemiumSubscription.create!({
      :subscription_plan => freemium_subscription_plans(:premium),
      :subscribable => User.new(:name => 'a'),
      :paid_through => Date.today - 1,
      :credit_card => FreemiumCreditCard.sample
    }.merge(options))
  end
end
