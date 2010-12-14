require 'spec_helper'

describe FreemiumSubscription do
  fixtures :users, :freemium_subscriptions, :freemium_subscription_plans, :freemium_credit_cards

  def build_subscription(options = {})
    FreemiumSubscription.new({
      :subscription_plan => freemium_subscription_plans(:free),
      :subscribable => users(:sue)
    }.merge(options))
  end

  def create_transaction_for(amount, subscription)
    FreemiumTransaction.create :amount => amount, :subscription => subscription, :success => true, :billing_key => 12345
  end

  def assert_changed(subscribable, reason, original_plan, new_plan)
    changes = FreemiumSubscriptionChange.where(["subscribable_id = ? AND subscribable_type = ?", subscribable.id, subscribable.class.to_s]).last
    changes.should_not be_nil
    changes.reason.should eql(reason.to_s)
    changes.original_subscription_plan.should eql(original_plan)
    changes.new_subscription_plan.should eq(new_plan)
    changes.original_rate_cents.should eql(original_plan ? original_plan.rate.cents : 0)
    changes.new_rate_cents.should eql(new_plan ? new_plan.rate.cents : 0)
  end

  it "should create free subscription" do
    subscription = build_subscription(:subscription_plan => freemium_subscription_plans(:free))
    subscription.save!

    subscription.should_not be_new_record
    subscription.reload.started_on.should eql(Date.today)
    subscription.in_trial?.should be_false
    subscription.paid_through.should be_nil
    subscription.paid?.should be_false

    #TODO understand what is that
    assert_changed(subscription.subscribable, :new, nil, freemium_subscription_plans(:free))
  end

  it "should create paid subscription" do
    Freemium.days_free_trial = 30

    subscription = build_subscription(:subscription_plan => freemium_subscription_plans(:basic), :credit_card => FreemiumCreditCard.sample)
    subscription.save!

    subscription.should_not be_new_record
    subscription.reload.started_on.should eql(Date.today)
    subscription.in_trial?.should be_true
    subscription.paid_through.should_not be_nil
    subscription.paid_through.should eql(Date.today + Freemium.days_free_trial)
    subscription.paid?.should be_true
    subscription.billing_key.should_not be_nil

    assert_changed(subscription.subscribable, :new, nil, freemium_subscription_plans(:basic))
  end

  it "should be upgraded from free" do
    subscription = build_subscription(:subscription_plan => freemium_subscription_plans(:free))
    subscription.save!

    new_date = Date.today + 10.days
    Date.stub!(:today => new_date)

    subscription.in_trial?.should be_false
    subscription.subscription_plan = freemium_subscription_plans(:basic)
    subscription.credit_card = FreemiumCreditCard.sample
    subscription.save!

    subscription.reload.started_on.should eql(new_date)
    subscription.paid_through.should_not be_nil
    subscription.in_trial?.should be_false
    subscription.paid_through.should eql(new_date)
    subscription.paid?.should be_true
    subscription.billing_key.should_not be_nil

    assert_changed(subscription.subscribable, :upgrade, freemium_subscription_plans(:free), freemium_subscription_plans(:basic))
  end

  it "should be downgraded" do
    subscription = build_subscription(:subscription_plan => freemium_subscription_plans(:basic), :credit_card => FreemiumCreditCard.sample)
    subscription.save!

    new_date = Date.today + 10.days
    Date.stub!(:today => new_date)

    subscription.subscription_plan = freemium_subscription_plans(:free)
    subscription.save!

    subscription.reload.started_on.should eql(new_date)
    subscription.paid_through.should be_nil
    subscription.paid?.should be_false
    subscription.billing_key.should be_nil
    subscription.credit_card.should be_nil

    assert_changed(subscription.subscribable, :downgrade, freemium_subscription_plans(:basic), freemium_subscription_plans(:free))
  end

  it "should have associations" do
    assert_equal users(:bob), freemium_subscriptions(:bobs_subscription).subscribable
    assert_equal freemium_subscription_plans(:basic), freemium_subscriptions(:bobs_subscription).subscription_plan
  end

  it "should have remaining_days" do
    assert_equal 20, freemium_subscriptions(:bobs_subscription).remaining_days
  end

  it "should have remaining_value" do
    assert_equal Money.new(840), freemium_subscriptions(:bobs_subscription).remaining_value
  end

  ##
  ## Upgrade / Downgrade service credits
  ##

  it "should upgrade credit" do
    subscription = freemium_subscriptions(:bobs_subscription)
    new_plan = freemium_subscription_plans(:premium)

    subscription.remaining_value.cents.should > 0
    expected_paid_through = Date.today + (subscription.remaining_value.cents / new_plan.daily_rate.cents)
    subscription.subscription_plan = freemium_subscription_plans(:premium)
    subscription.save!

    subscription.paid_through.should eql(expected_paid_through)
  end

  it "should upgrade no credit for free trial" do
    subscription = build_subscription(:subscription_plan => freemium_subscription_plans(:premium), :credit_card => FreemiumCreditCard.sample)
    subscription.save!

    subscription.paid_through.should eql(Date.today + Freemium.days_free_trial)
    subscription.in_trial?.should be_true

    subscription.subscription_plan = freemium_subscription_plans(:basic)
    subscription.save!

    subscription.paid_through.should eql(Date.today)
    subscription.in_trial?.should be_false
  end

  ##
  ## Validations
  ##

  it "should test missing fields" do
    [:subscription_plan, :subscribable].each do |field|
      subscription = build_subscription(field => nil)
      subscription.save

      subscription.should be_new_record
      subscription.should have(1).errors_on(field)
    end
  end

  ##
  ## Receiving payment
  ##

  it "should receive monthly payment" do
    subscription = freemium_subscriptions(:bobs_subscription)
    paid_through = subscription.paid_through
    subscription.credit(freemium_subscription_plans(:basic).rate)
    subscription.save!

    subscription.paid_through.to_s.should eql((paid_through >> 1).to_s) #extended by one month
    subscription.transactions.should_not be_nil
  end

  its "should receive quarterly payment" do
    subscription = freemium_subscriptions(:bobs_subscription)
    paid_through = subscription.paid_through
    subscription.credit(freemium_subscription_plans(:basic).rate * 3)
    subscription.save!
    subscription.paid_through.to_s.should eql((paid_through >> 3).to_s) #extended by three months
  end

  it "should receive partial payment" do
    subscription = freemium_subscriptions(:bobs_subscription)
    paid_through = subscription.paid_through
    subscription.credit(freemium_subscription_plans(:basic).rate * 0.5)
    subscription.save!
    subscription.paid_through.to_s.should eql((paid_through + 15).to_s) #extended by 15 days
  end

  it "should send invoice when receiving payment" do
    subscription = freemium_subscriptions(:bobs_subscription)
    ActionMailer::Base.deliveries = []
    transaction = create_transaction_for(freemium_subscription_plans(:basic).rate, subscription)
    subscription.receive_payment!(transaction)
    ActionMailer::Base.deliveries.size.should eql(1)
  end

  it "should save transaction message when receiving payment" do
    subscription = freemium_subscriptions(:bobs_subscription)
    transaction = create_transaction_for(freemium_subscription_plans(:basic).rate, subscription)
    subscription.receive_payment!(transaction)
    transaction.reload.message.should match(/^now paid through/)
  end

  it "should receive payment though invoice has delivered with error" do
    subscription = freemium_subscriptions(:bobs_subscription)
    paid_through = subscription.paid_through
    transaction = create_transaction_for(freemium_subscription_plans(:basic).rate, subscription)
    Freemium.mailer.should_receive(:invoice).and_raise(RuntimeError)
    subscription.receive_payment!(transaction)
    subscription = subscription.reload
    subscription.paid_through.to_s.should eql((paid_through >> 1).to_s) #extended by one month
  end

  ##
  ## Requiring Credit Cards ...
  ##

  it "should require credit card for pay plan" do
    subscription = build_subscription(:subscription_plan => freemium_subscription_plans(:premium))
    subscription.stub!(:credit_card => nil)
    subscription.should have(1).errors_on(:credit_card)
  end

  it "should not require credit card for free_plan" do
    subscription = build_subscription
    subscription.should have(0).errors_on(:credit_card)
  end

  ##
  ## Expiration
  ##

  it "should expire instance" do
    Freemium.expired_plan_key = :free
    Freemium.gateway.should_receive(:cancel).once.and_return(nil)
    ActionMailer::Base.deliveries = []
    freemium_subscriptions(:bobs_subscription).expire!

    ActionMailer::Base.deliveries.size.should eql(1) #notice is sent to user
    freemium_subscriptions(:bobs_subscription).reload.subscription_plan.should eql(freemium_subscription_plans(:free)) #subscription is downgraded to free
    freemium_subscriptions(:bobs_subscription).billing_key.should be_nil #billing key is thrown away
    freemium_subscriptions(:bobs_subscription).reload.billing_key.should be_nil #billing key is thrown away

    assert_changed(freemium_subscriptions(:bobs_subscription).subscribable, :expiration, freemium_subscription_plans(:basic), freemium_subscription_plans(:free))
  end

  it "should expire instance with expired_plan_key = nil" do
    Freemium.expired_plan_key = nil
    Freemium.gateway.should_receive(:cancel).once.and_return(nil)
    ActionMailer::Base.deliveries = []
    freemium_subscriptions(:bobs_subscription).expire!

    ActionMailer::Base.deliveries.size.should eql(1) #notice is sent to user
    freemium_subscriptions(:bobs_subscription).subscription_plan.should eql(freemium_subscription_plans(:basic)) #subscription was not changed
    freemium_subscriptions(:bobs_subscription).billing_key.should be_nil #billing key is thrown away
    freemium_subscriptions(:bobs_subscription).reload.billing_key.should be_nil #billing key is thrown away
  end

  it "should expire class" do
    Freemium.expired_plan_key = :free
    Freemium.expired_plan_key.should eql(:free)
    Freemium.expired_plan.should_not be_nil
    freemium_subscriptions(:bobs_subscription).update_attributes(:paid_through => Date.today - 4, :expire_on => Date.today)
    ActionMailer::Base.deliveries = []

    freemium_subscriptions(:bobs_subscription).subscription_plan.should eql(freemium_subscription_plans(:basic))

    Freemium.expired_plan.should eql(freemium_subscription_plans(:free))
    FreemiumSubscription.expire

    freemium_subscriptions(:bobs_subscription).expire!
    freemium_subscriptions(:bobs_subscription).reload.subscription_plan.should eql(freemium_subscription_plans(:free))
    freemium_subscriptions(:bobs_subscription).reload.started_on.should eql(Date.today)
    ActionMailer::Base.deliveries.size.should > 0

    assert_changed(freemium_subscriptions(:bobs_subscription).subscribable, :expiration, freemium_subscription_plans(:basic), freemium_subscription_plans(:free)) 
  end

  it "should expire after grace " do
    freemium_subscriptions(:bobs_subscription).expire_on.should be_nil
    freemium_subscriptions(:bobs_subscription).paid_through = Date.today - 2
    ActionMailer::Base.deliveries = []

    freemium_subscriptions(:bobs_subscription).expire_after_grace!

    ActionMailer::Base.deliveries.size.should eql(1)
    freemium_subscriptions(:bobs_subscription).reload.expire_on.should eql(Date.today + Freemium.days_grace)
  end

  it "should expire after grace with remaining period" do
    freemium_subscriptions(:bobs_subscription).paid_through = Date.today + 1
    freemium_subscriptions(:bobs_subscription).expire_after_grace!

    freemium_subscriptions(:bobs_subscription).reload.expire_on.should eql(Date.today + 1 + Freemium.days_grace)
  end

  it "should test grace and expiration" do
    Freemium.days_grace.should eql(3)

    subscription = FreemiumSubscription.new(:paid_through => Date.today + 5)
    subscription.in_grace?.should be_false
    subscription.expired?.should be_false

    # a subscription that's pastdue but hasn't been flagged to expire yet.
    # this could happen if a billing process skips, in which case the subscriber
    # should still get a full grace period beginning from the failed attempt at billing.
    # even so, the subscription is "in grace", even if the grace period hasn't officially started.
    subscription = FreemiumSubscription.new(:paid_through => Date.today - 5)
    subscription.in_grace?.should be_true
    subscription.expired?.should be_false

    # expires tomorrow
    subscription = FreemiumSubscription.new(:paid_through => Date.today - 5, :expire_on => Date.today + 1)
    subscription.remaining_days_of_grace.should eql(0)
    subscription.in_grace?.should be_true
    subscription.expired?.should be_false

    # expires today
    subscription = FreemiumSubscription.new(:paid_through => Date.today - 5, :expire_on => Date.today)
    subscription.remaining_days_of_grace.should eql(-1)
    subscription.in_grace?.should be_false
    subscription.expired?.should be_true
  end

  ##
  ## Deleting (possibly from a cascading delete, such as User.find(5).delete)
  ##

  it "should delete canceles in gateway" do
    Freemium.gateway.should_receive(:cancel).once.and_return(nil)
    freemium_subscriptions(:bobs_subscription).destroy

    assert_changed(freemium_subscriptions(:bobs_subscription).subscribable, :cancellation, freemium_subscription_plans(:basic), nil)    
  end

  ##
  ## The Subscription#credit_card= shortcut
  ##
  it "should add credit card" do
    subscription = build_subscription(:subscription_plan => freemium_subscription_plans(:premium))
    cc = FreemiumCreditCard.sample
    response = Freemium::Response.new(true)
    response.billing_key = "alphabravo"
    Freemium.gateway.should_receive(:store).with(cc, cc.address).and_return(response)

    subscription.credit_card = cc
    lambda { subscription.save! }.should_not raise_error
    subscription.billing_key.should eql("alphabravo")
  end

  it "should update a credit card" do
    subscription = FreemiumSubscription.where("billing_key IS NOT NULL").first
    cc = FreemiumCreditCard.sample
    response = Freemium::Response.new(true)
    response.billing_key = "new code"
    Freemium.gateway.should_receive(:update).with(subscription.billing_key, cc, cc.address).and_return(response)

    subscription.credit_card = cc
    lambda { subscription.save! }.should_not raise_error
    subscription.billing_key.should eql("new code") #catches any change to the billing key
  end

  it "should update an expired credit card" do
    subscription = FreemiumSubscription.where("billing_key IS NOT NULL").first
    cc = FreemiumCreditCard.sample
    response = Freemium::Response.new(true)
    Freemium.gateway.should_receive(:update).with(subscription.billing_key, cc, cc.address).and_return(response)

    subscription.expire_on = Time.now
    subscription.save.should be_true
    subscription.reload.expire_on.should_not be_nil

    subscription.credit_card = cc
    lambda { subscription.save! }.should_not raise_error
    subscription.expire_on.should be_nil
    subscription.reload.expire_on.should be_nil
  end

  it "should fail to add credit card" do
    subscription = build_subscription(:subscription_plan => freemium_subscription_plans(:premium))
    cc = FreemiumCreditCard.sample
    response = Freemium::Response.new(false)
    Freemium.gateway.should_receive(:store).and_return(response)

    subscription.credit_card = cc
    lambda { subscription.save! }.should raise_error(Freemium::CreditCardStorageError)
  end

end
