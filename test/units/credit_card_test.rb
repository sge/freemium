require File.dirname(__FILE__) + '/../test_helper'

class CreditCardTest < ActiveSupport::TestCase
fixtures :users, :freemium_subscriptions, :freemium_subscription_plans, :freemium_credit_cards
  
  def setup
    @subscription = FreemiumSubscription.new(:subscription_plan => freemium_subscription_plans(:premium), :subscribable => users(:sally))
    @credit_card = FreemiumCreditCard.new(FreemiumCreditCard.sample_params.merge(:subscription => @subscription))
        
    Freemium.gateway = Freemium::Gateways::BrainTree.new
    Freemium.gateway.username = 'demo'
    Freemium.gateway.password = 'password'

    Freemium.gateway.stubs(:validate_card).returns(Freemium::Response.new(true))
  end
  
  def test_create
    @subscription.credit_card = @credit_card

    assert @subscription.save
    @subscription = FreemiumSubscription.find(@subscription.id)
    assert_not_nil @subscription.billing_key
    assert_not_nil @subscription.credit_card.display_number
    assert_not_nil @subscription.credit_card.card_type
    assert_not_nil @subscription.credit_card.expiration_date
  end

  def test_create_with_billing_validation_failure
    Freemium.gateway.stubs(:validate_card).returns(Freemium::Response.new(false, 'responsetext' => 'FAILED'))

    @subscription.credit_card = @credit_card

    assert_raises Freemium::CreditCardStorageError do
      @subscription.save
    end
  end

  def test_update
    @subscription.credit_card = @credit_card

    assert @subscription.save
    @subscription = FreemiumSubscription.find(@subscription.id)
    assert_not_nil @subscription.billing_key

    original_key = @subscription.billing_key
    original_expiration = @subscription.credit_card.expiration_date
    
    @subscription.credit_card = FreemiumCreditCard.new(FreemiumCreditCard.sample_params.merge(:zip_code => 95060, :number => "5431111111111111", :card_type => "master", :year => 2020))
    assert @subscription.save
    @subscription = FreemiumSubscription.find(@subscription.id)
    assert_equal original_key, @subscription.billing_key
    assert @subscription.credit_card.expiration_date > original_expiration
    assert_equal "95060", @subscription.credit_card.reload.zip_code
  end
    
  ##
  ## Test Validations
  ##

  def test_create_invalid_number
    @credit_card.number = "foo"
    assert !@credit_card.valid?
    assert !@credit_card.save
  end

  def test_create_expired_card
    @credit_card.year = 2001
    assert !@credit_card.valid?
    assert !@credit_card.save
  end
  
  def test_changed_on_new
    # We're overriding AR#changed? to include instance vars that aren't persisted to see if a new card is being set
    assert @credit_card.changed?, "New card is changed"
  end  
  
  def test_changed_after_reload
    @credit_card.save!
    @credit_card = FreemiumCreditCard.find(@credit_card.id)
    assert !@credit_card.reload.changed?, "Saved card is NOT changed"
  end       
  
  def test_changed_existing
    assert !freemium_credit_cards(:bobs_credit_card).changed?
  end  
    
  def test_changed_after_update
    freemium_credit_cards(:bobs_credit_card).number = "foo"
    assert freemium_credit_cards(:bobs_credit_card).changed?
  end
  
  def test_validate_on_new
    assert @credit_card.valid?, "New card is valid"
  end
  
  def test_validate_existing_unchanged
    # existing cards on file are valid ...
    assert !freemium_credit_cards(:bobs_credit_card).changed?, "Existing card has not changed"
    assert freemium_credit_cards(:bobs_credit_card).valid?, "Existing card is valid"
  end
    
  def test_validate_existing_changed_number
    # ... unless theres an attempt to update them
    freemium_credit_cards(:bobs_credit_card).number = "foo"
    assert !freemium_credit_cards(:bobs_credit_card).valid?, "Partially changed existing card is not valid"
  end
  
  def test_validate_existing_changed_card_type
    # ... unless theres an attempt to update them
    freemium_credit_cards(:bobs_credit_card).card_type = "visa"
    assert !freemium_credit_cards(:bobs_credit_card).valid?, "Partially changed existing card is not valid"
  end  
  
end