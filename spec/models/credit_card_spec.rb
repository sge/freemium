require 'spec_helper'

describe CreditCard do
  fixtures :users, :subscriptions, :subscription_plans, :credit_cards

  before(:each) do
    @subscription = Subscription.new(:subscription_plan => subscription_plans(:premium), :subscribable => users(:sally))
    @credit_card = CreditCard.new(CreditCard.sample_params.merge(:subscription => @subscription))
    Freemium.gateway = Freemium::Gateways::BrainTree.new
    Freemium.gateway.username = 'demo'
    Freemium.gateway.password = 'password'

    Freemium.gateway.stub!(:validate => Freemium::Response.new(true))
  end

  it "should create" do
    @subscription.credit_card = @credit_card

    @subscription.save.should be_true
    @subscription = Subscription.find(@subscription.id)
    @subscription.billing_key.should_not be_nil
    @subscription.credit_card.display_number.should_not be_nil
    @subscription.credit_card.card_type.should_not be_nil
    @subscription.credit_card.expiration_date.should_not be_nil
  end

  it "should be created with billing validation failure" do
    response = Freemium::Response.new(false, 'responsetext' => 'FAILED')
    response.message = 'FAILED'
    Freemium.gateway.stub!(:validate => response)

    @subscription.credit_card = @credit_card

    @subscription.save.should be_false
    @subscription.should have(1).errors_on(:base)
  end

  it "should be updated" do
    @subscription.credit_card = @credit_card

    @subscription.save.should be_true
    @subscription = Subscription.find(@subscription.id)
    @subscription.billing_key.should_not be_nil

    original_key = @subscription.billing_key
    original_expiration = @subscription.credit_card.expiration_date

    @subscription.credit_card = CreditCard.new(CreditCard.sample_params.merge(:zip_code => 95060, :number => "5431111111111111", :card_type => "master", :year => 2020))
    @subscription.save.should be_true
    @subscription = Subscription.find(@subscription.id)
    @subscription.billing_key.should eql(original_key)
    original_expiration.should < @subscription.credit_card.expiration_date
    @subscription.credit_card.reload.zip_code.should eql("95060")
  end

  ##
  ## Test Validations
  ##

  it "should validate card number" do
    @credit_card.number = "foo"
    @credit_card.should_not be_valid
    @credit_card.save.should be_false
  end

  it "should validate expiration date of card" do
    @credit_card.year = 2001
    @credit_card.should_not be_valid
    @credit_card.save.should be_false
  end

  it "should be changed" do
    # We're overriding AR#changed? to include instance vars that aren't persisted to see if a new card is being set
    @credit_card.changed?.should be_true #New card is changed
  end

  it "should be changed after reload" do
    @credit_card.save!
    @credit_card = CreditCard.find(@credit_card.id)
    @credit_card.reload.changed?.should be_false #Saved card is NOT changed
  end

  it "should not be chanegd for existent card" do
    credit_cards(:bobs_credit_card).changed?.should be_false
  end

  it "should be chnaged after update" do
    credit_cards(:bobs_credit_card).number = "foo"
    credit_cards(:bobs_credit_card).changed?.should be_true
  end

  it "should be valid" do
    @credit_card.should be_valid #New card is valid
  end

  it "should be valid and unchanged for existent cards" do
    # existing cards on file are valid ...
    credit_cards(:bobs_credit_card).changed?.should be_false #Existing card has not changed
    credit_cards(:bobs_credit_card).should be_valid #Existing card is valid
  end

  it "should validate number of existent card" do
    # ... unless theres an attempt to update them
    credit_cards(:bobs_credit_card).number = "foo"
    credit_cards(:bobs_credit_card).should_not be_valid #Partially changed existing card is not valid
  end

  it "should validate card type of existent card" do
    # ... unless theres an attempt to update them
    credit_cards(:bobs_credit_card).card_type = "visa"
    credit_cards(:bobs_credit_card).should_not be_valid  #Partially changed existing card is not valid
  end

end
