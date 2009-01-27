require File.dirname(__FILE__) + '/../test_helper'

class SubscriptionPlanTest < Test::Unit::TestCase
  fixtures :users, :freemium_subscriptions, :freemium_subscription_plans, :freemium_credit_cards

  def test_associations
    assert_equal [freemium_subscriptions(:bobs_subscription)], freemium_subscription_plans(:basic).subscriptions
  end

  def test_rate_intervals
    plan = FreemiumSubscriptionPlan.new(:rate_cents => 3041)
    assert_equal Money.new(99), plan.daily_rate
    assert_equal Money.new(3041), plan.monthly_rate
    assert_equal Money.new(36492), plan.yearly_rate
  end

  def test_creating_plan
    plan = create_plan
    assert !plan.new_record?, plan.errors.full_messages.to_sentence
  end

  def test_missing_fields
    [:name, :rate_cents].each do |field|
      plan = create_plan(field => nil)
      assert plan.new_record?
      assert plan.errors.on(field)
    end
  end
  
  ##
  ## Feature sets
  ##

  def test_free_has_ads
    assert freemium_subscription_plans(:free).features.ads?
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