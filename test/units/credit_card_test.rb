require File.dirname(__FILE__) + '/../test_helper'

class CreditCardTest < Test::Unit::TestCase
  fixtures :subscriptions, :credit_cards, :subscription_plans, :users
  
  # TODO: DRY this up with the AccountsControllerTest
  def setup
    @first_card_params = CreditCard.example_params
    
    @subscription = Subscription.new(:subscription_plan => subscription_plans(:premium), :subscribable => users(:sally))
    @credit_card = CreditCard.new(@first_card_params.merge(:subscription => @subscription))   
        
    Freemium.gateway = Freemium::Gateways::BrainTree.new
    Freemium.gateway.username = 'demo'
    Freemium.gateway.password = 'password'
  end
  
  def test_create
    @subscription.create_credit_card(@first_card_params)
    assert @subscription.save
    @subscription = Subscription.find(@subscription.id)
    assert_not_nil @subscription.billing_key
    assert_not_nil @subscription.credit_card.display_number
    assert_not_nil @subscription.credit_card.card_type
    assert_not_nil @subscription.credit_card.expiration_date
  end  
  
  def test_update
    @subscription.credit_card = CreditCard.new(@first_card_params)
    assert @subscription.save
    @subscription = Subscription.find(@subscription.id)
    assert_not_nil @subscription.billing_key

    original_key = @subscription.billing_key
    original_expiration = @subscription.credit_card.expiration_date
    
    @subscription.credit_card = CreditCard.new(@first_card_params.merge(:number => "5431111111111111", :card_type => "master", :year => 2020))
    assert @subscription.save
    @subscription = Subscription.find(@subscription.id)
    assert_equal original_key, @subscription.billing_key
    assert @subscription.credit_card.expiration_date > original_expiration
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
    @credit_card = CreditCard.find(@credit_card.id)
    assert !@credit_card.reload.changed?, "Saved card is NOT changed"
  end       
  
  def test_changed_existing
    assert !credit_cards(:bobs_credit_card).changed?
  end  
    
  def test_changed_after_update
    credit_cards(:bobs_credit_card).number = "foo"
    assert credit_cards(:bobs_credit_card).changed?
  end
  
  def test_validate_on_new
    assert @credit_card.valid?, "New card is valid"
  end
  
  def test_validate_existing_unchanged
    # existing cards on file are valid ...
    assert !credit_cards(:bobs_credit_card).changed?, "Existing card has not changed"
    assert credit_cards(:bobs_credit_card).valid?, "Existing card is valid"
  end
    
  def test_validate_existing_changed_number
    # ... unless theres an attempt to update them
    credit_cards(:bobs_credit_card).number = "foo"
    assert !credit_cards(:bobs_credit_card).valid?, "Partially changed existing card is not valid"
  end
  
  def test_validate_existing_changed_card_type
    # ... unless theres an attempt to update them
    credit_cards(:bobs_credit_card).card_type = "visa"
    assert !credit_cards(:bobs_credit_card).valid?, "Partially changed existing card is not valid"
  end  
  
end