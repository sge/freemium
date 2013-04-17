require 'spec_helper'

describe SubscriptionPlan do
  fixtures :users, :subscriptions, :subscription_plans, :credit_cards

  it "should have associations" do
    [subscriptions(:bobs_subscription)].should == (subscription_plans(:basic).subscriptions)
  end

  it "should have rate intervals" do
    plan = SubscriptionPlan.new(:rate_cents => 3041)
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
    subscription_plans(:free).features.ads?.should_not be_nil
  end

  protected

  def create_plan(options = {})
    SubscriptionPlan.create({
      :name => 'super-duper-ultra-premium',
      :redemption_key => 'super-duper-ultra-premium',
      :rate_cents => 99995,
      :feature_set_id => :premium
    }.merge(options))
  end
end
