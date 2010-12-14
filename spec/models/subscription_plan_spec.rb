require 'spec_helper'

describe FreemiumSubscriptionPlan do
  fixtures :users, :freemium_subscriptions, :freemium_subscription_plans, :freemium_credit_cards

  it "should have associations" do
    [freemium_subscriptions(:bobs_subscription)].should == (freemium_subscription_plans(:basic).subscriptions)
  end

  it "should have rate intervals" do
    plan = FreemiumSubscriptionPlan.new(:rate_cents => 3041)
    plan.daily_rate.should eql(Money.new(99))
    plan.monthly_rate.should eql(Money.new(3041))
    plan.yearly_rate.should eql(Money.new(36492))
  end

  it "should create plan" do
    plan = create_plan
    plan.new_record?.should be_false
  end

  it "should have errors" do
    [:name, :rate_cents].each do |field|
      plan = create_plan(field => nil)
      plan.new_record?.should be_true
      plan.should have(1).errors_on(field)
    end
  end

  it "should have ads" do
    freemium_subscription_plans(:free).features.ads?.should_not be_nil
  end

  protected

  def create_plan(options = {})
    FreemiumSubscriptionPlan.create({
      :name => 'super-duper-ultra-premium',
      :redemption_key => 'super-duper-ultra-premium',
      :rate_cents => 99995,
      :feature_set_id => :premium
    }.merge(options))
  end
end
