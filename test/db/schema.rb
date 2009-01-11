ActiveRecord::Schema.define(:version => 1) do
  create_table :users, :force => true do |t|
    t.column :name, :string
    t.column :email, :string
  end
  
  create_table :subscription_plans, :force => true do |t|
    t.column :name, :string, :null => false
    t.column :key, :string, :null => false
    t.column :rate_cents, :integer, :null => false
    t.column :feature_set_id, :string, :null => false
  end

  create_table :subscriptions, :force => true do |t|
    t.column :subscribable_id, :integer, :null => false
    t.column :subscribable_type, :string, :null => false
    t.column :billing_key, :string, :null => true
    t.column :credit_card_id, :integer, :null => true
    t.column :subscription_plan_id, :integer, :null => false
    t.column :paid_through, :date
    t.column :expire_on, :date, :null => true
    t.column :billing_key, :string, :null => true
    t.column :started_on, :date, :null => true
    t.column :last_transaction_at, :datetime, :null => true
  end
  
  create_table :credit_cards, :force => true do |t|
    t.column :display_number, :string, :null => false
    t.column :card_type, :string, :null => false
    t.column :expiration_date, :timestamp, :null => false
  end  
  
  create_table :coupons, :force => true do |t|  
    t.column :description, :string, :null => false
    t.column :discount_percentage, :integer, :null => false 
    t.column :redemption_limit, :integer, :null => true 
    t.column :redemption_expiration, :date, :null => true
    t.column :duration_in_months, :integer, :null => true
    #    t.column :redemption_key, :string, :null => true
  end
  
  create_table :subscription_coupons, :force => true do |t|  
    t.column :subscription_id, :integer, :null => false
    t.column :coupon_id, :integer, :null => false 
    t.column :created_on, :datetime, :null => false 
    t.column :deleted_at, :datetime, :null => true
  end  
  
end