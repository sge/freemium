require 'spec_helper'

describe FreemiumCouponRedemption do
  fixtures :users, :freemium_subscriptions, :freemium_subscription_plans, :freemium_credit_cards

  before(:each) do
    @subscription = freemium_subscriptions(:bobs_subscription)
    @original_price = @subscription.rate
    @coupon = FreemiumCoupon.create(:description => "30% off", :discount_percentage => 30, :redemption_key => "30OFF")
  end

  it "should be applied" do
    @subscription.paid_through = Date.today + 30
    @original_remaining_value = @subscription.remaining_value
    @original_daily_rate = @subscription.daily_rate
    @subscription.coupon_key = nil

    @subscription.coupon_redemptions.create(:coupon => @coupon).should be_true
    @subscription.rate.cents.should eql(@coupon.discount(@original_price).cents)
    @subscription.daily_rate.cents.should eql(@coupon.discount(@original_daily_rate).cents)
    @subscription.remaining_value.cents.should eql((@coupon.discount(@original_daily_rate) * @subscription.remaining_days).cents)
  end

  it "should be applied using coupon accessor" do
    @subscription = build_subscription(:coupon => @coupon, :credit_card => FreemiumCreditCard.sample)
    @subscription.save!

    @subscription.coupon.should_not be_nil
    @subscription.coupon_redemptions.first.coupon.should_not be_nil
    @subscription.coupon_redemptions.first.subscription.should_not be_nil
    @subscription.coupon_redemptions.empty?.should be_false
    @subscription.rate.cents.should eql(@coupon.discount(@subscription.subscription_plan.rate).cents)
  end

  it "should be applied using coupon key accessor" do
    @subscription = build_subscription(:coupon_key => @coupon.redemption_key, :credit_card => FreemiumCreditCard.sample)
    @subscription.save!

    @subscription.coupon.should_not be_nil
    @subscription.coupon_redemptions.first.coupon.should_not be_nil
    @subscription.coupon_redemptions.first.subscription.should_not be_nil
    @subscription.coupon_redemptions.empty?.should be_false
    @subscription.rate.cents.should eql(@coupon.discount(@subscription.subscription_plan.rate).cents)
  end

  it "should be applied multiple" do
    @coupon_1 = FreemiumCoupon.new(:description => "10% off", :discount_percentage => 10)
    @subscription.coupon_redemptions.create(:coupon => @coupon_1).should be_true

    @coupon_2 = FreemiumCoupon.new(:description => "30% off", :discount_percentage => 30)
    @subscription.coupon_redemptions.create(:coupon => @coupon_2).should be_true

    @coupon_3 = FreemiumCoupon.new(:description => "20% off", :discount_percentage => 20)
    @subscription.coupon_redemptions.create(:coupon => @coupon_3).should be_true

    # Should use the highest discounted coupon
    @subscription.rate.cents.should eql(@coupon_2.discount(@original_price).cents)
  end

  it "should be destroyed" do
    @subscription.coupon_redemptions.create(:coupon => @coupon).should be_true
    @subscription.rate.cents.should eql(@coupon.discount(@original_price).cents)

    @coupon.destroy
    @subscription.reload

    @subscription.coupon_redemptions.empty?.should be_true
    @subscription.rate.cents.should eql(@original_price.cents)
  end

  it "should test coupon duration" do
    @subscription.coupon_redemptions.create(:coupon => @coupon).should be_true
    @subscription.rate.cents.should eql(@coupon.discount(@original_price).cents)

    @coupon.duration_in_months = 3
    @coupon.save!

    @subscription.rate({:date => (Date.today + 3.months - 1)}).cents.should eql(@coupon.discount(@original_price).cents)
    @subscription.rate({:date => (Date.today + 3.months + 1)}).cents.should eql(@original_price.cents)

    safe_date = Date.today + 3.months - 1
    Date.stub!(:today => safe_date)
    @subscription.rate.cents.should eql(@coupon.discount(@original_price).cents)

    safe_date = Date.today + 1
    Date.stub!(:today => safe_date)
    @subscription.rate.cents.should eql(@coupon.discount(@original_price).cents)

    safe_date = Date.today + 1
    Date.stub!(:today => safe_date)
    @subscription.rate.cents.should eql(@original_price.cents)
  end

  it "should be applied complimentary" do
    @coupon.discount_percentage = 100

    @subscription = build_subscription(:coupon => @coupon, :credit_card => FreemiumCreditCard.sample, :subscription_plan => freemium_subscription_plans(:premium))

    @subscription.save.should be_true
    @subscription.coupon.should_not be_nil
    @subscription.rate.cents.should eql(0)
    @subscription.paid?.should be_false
  end

  ##
  ## Plan-specific coupons
  ##

  it "should be applied only on new premium plan" do
    set_coupon_to_premium_only

    @subscription = build_subscription(:coupon => @coupon, :credit_card => FreemiumCreditCard.sample,
                                       :subscription_plan => freemium_subscription_plans(:premium))

    @subscription.save.should be_true
    @subscription.coupon.should_not be_nil

    @subscription = build_subscription(:coupon => @coupon, :credit_card => FreemiumCreditCard.sample,
                                       :subscription_plan => freemium_subscription_plans(:basic))

    @subscription.save.should be_false
    @subscription.should have(1).errors_on(:coupon_redemptions)
  end

  it "should be applied only on existent premium plan" do
    set_coupon_to_premium_only

    @subscription.coupon = @coupon

    @subscription.subscription_plan.should eql(freemium_subscription_plans(:basic))
    @subscription.save.should be_false
    @subscription.should have(1).errors_on(:coupon_redemptions)

    @subscription.subscription_plan = freemium_subscription_plans(:premium)

    @subscription.subscription_plan.should eql(freemium_subscription_plans(:premium))
    @subscription.save.should be_true
    @subscription.coupon.should_not be_nil
  end

  ##
  ## applying coupons
  ##

  it "should be applied to subscription" do
    @subscription.coupon = @coupon
    @subscription.should be_valid
    @subscription.coupon.should_not be_nil
  end

  it "should validate coupon key" do
    @subscription.coupon_key = @coupon.redemption_key + "xxxxx"

    @subscription.should_not be_valid
    @subscription.coupon.should be_nil
    @subscription.should have(1).errors_on(:coupon)
  end

  it "should validate coupon by coupon plan" do
    set_coupon_to_premium_only

    @subscription.subscription_plan.should_not eql(freemium_subscription_plans(:premium))

    @subscription.coupon = @coupon
    @subscription.should_not be_valid
    @subscription.should have(1).errors_on(:coupon_redemptions)
  end

  protected

  def set_coupon_to_premium_only
    @coupon.subscription_plans << freemium_subscription_plans(:premium)
    @coupon.save!
  end


  public

  ##
  ## Validation Tests
  ##

  it "should validate coupon" do
    s = FreemiumCouponRedemption.new(:subscription => freemium_subscriptions(:bobs_subscription))
    s.save.should be_false
    s.should have(1).errors_on(:coupon)
  end

  it "should not be applied to unpaid subscription" do
    freemium_subscriptions(:sues_subscription).paid?.should be_false
    s = FreemiumCouponRedemption.new(:subscription => freemium_subscriptions(:sues_subscription), :coupon => @coupon)
    s.save.should be_false
    s.should have(1).errors_on(:subscription)
  end

  it "should not be applied twice" do
    s = FreemiumCouponRedemption.new(:subscription => freemium_subscriptions(:bobs_subscription), :coupon => @coupon)
    s.save.should be_true

    s = FreemiumCouponRedemption.new(:subscription => freemium_subscriptions(:bobs_subscription), :coupon => @coupon)
    s.save.should be_false
    s.should have(1).errors_on(:coupon_id)
  end

  it "should not be applied with redemption expired coupon" do
    @coupon.redemption_expiration = Date.today-1
    @coupon.save!

    s = FreemiumCouponRedemption.new(:subscription => freemium_subscriptions(:bobs_subscription), :coupon => @coupon)
    s.save.should be_false
    s.should have(1).errors_on(:coupon)
  end

  it "should not be applied with too many redemptions" do
    @coupon.redemption_limit = 1
    @coupon.save!

    s = FreemiumCouponRedemption.new(:subscription => freemium_subscriptions(:bobs_subscription), :coupon => @coupon)
    s.save!

    s = FreemiumCouponRedemption.new(:subscription => freemium_subscriptions(:steves_subscription), :coupon => @coupon)
    s.save.should be_false
    s.should have(1).errors_on(:coupon)
  end

  protected

  def build_subscription(options = {})
    FreemiumSubscription.new({
      :subscription_plan => freemium_subscription_plans(:basic),
      :subscribable => users(:sue)
    }.merge(options))
  end

end
