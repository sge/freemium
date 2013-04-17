class CreateFreemiumSchema < ActiveRecord::Migration
  def self.up

    create_table :account_transactions, :force => true do |t|
      t.column :subscription_id, :integer, :null => false
      t.column :success, :boolean, :null => false
      t.column :billing_key, :string, :null => false
      t.column :amount_cents, :integer, :null => false
      t.column :message, :string, :null => true
      t.column :created_at, :timestamp, :null => false
    end

    add_index :account_transactions, :subscription_id
    
    create_table :coupon_redemptions, :force => true do |t|
      t.column :subscription_id, :integer, :null => false
      t.column :coupon_id, :integer, :null => false
      t.column :redeemed_on, :date, :null => false
      t.column :expired_on, :date, :null => true
    end

    add_index :coupon_redemptions, :subscription_id
    
    create_table :coupons, :force => true do |t|
      t.column :description, :string, :null => false
      t.column :discount_percentage, :integer, :null => false
      t.column :redemption_key, :string, :null => true
      t.column :redemption_limit, :integer, :null => true
      t.column :redemption_expiration, :date, :null => true
      t.column :duration_in_months, :integer, :null => true
    end

    create_table :coupons_subscription_plans, :id => false, :force => true do |t|
      t.column :coupon_id, :integer, :null => false
      t.column :subscription_plan_id, :integer, :null => false
    end

    add_index :coupons_subscription_plans, :coupon_id, :name => :on_coupon_id
    add_index :coupons_subscription_plans, :subscription_plan_id, :name => :on_subscription_plan_id

    create_table :credit_cards, :force => true do |t|
      t.column :display_number, :string, :null => false
      t.column :card_type, :string, :null => false
      t.column :expiration_date, :timestamp, :null => false
      t.column :zip_code, :string, :null => true
    end

    create_table :subscription_changes, :force => true do |t|
      t.column :subscribable_id, :integer, :null => false
      t.column :subscribable_type, :string, :null => false
      t.column :original_subscription_plan_id, :integer, :null => true
      t.column :new_subscription_plan_id, :integer, :null => true
      t.column :original_rate_cents, :integer, :null => true
      t.column :new_rate_cents, :integer, :null => true
      t.column :reason, :string, :null => false
      t.column :created_at, :timestamp, :null => false
    end

    add_index :subscription_changes, :reason
    add_index :subscription_changes, [:subscribable_id, :subscribable_type], :name => :on_subscribable_id_and_type

    create_table :subscription_plans, :force => true do |t|
      t.column :name, :string, :null => false
      t.column :redemption_key, :string, :null => false
      t.column :rate_cents, :integer, :null => false
      t.column :feature_set_id, :string, :null => false
    end

    create_table :subscriptions, :force => true do |t|
      t.column :subscribable_id, :integer, :null => false
      t.column :subscribable_type, :string, :null => false
      t.column :billing_key, :string, :null => true
      t.column :credit_card_id, :integer, :null => true
      t.column :subscription_plan_id, :integer, :null => false
      t.column :paid_through, :date, :null => true
      t.column :expire_on, :date, :null => true
      t.column :billing_key, :string, :null => true
      t.column :started_on, :date, :null => true
      t.column :last_transaction_at, :datetime, :null => true
      t.column :in_trial, :boolean, :null => false, :default => false
    end

    # for polymorphic association queries
    add_index :subscriptions, :subscribable_id
    add_index :subscriptions, :subscribable_type
    add_index :subscriptions, [:subscribable_id, :subscribable_type], :name => :on_subscribable_id_and_type
    
    # for finding due, pastdue, and expiring subscriptions
    add_index :subscriptions, :paid_through
    add_index :subscriptions, :expire_on
    
    # for applying transactions from automated recurring billing
    add_index :subscriptions, :billing_key
  end

  def self.down
    drop_table :account_transactions
    drop_table :coupon_redemptions
    drop_table :coupons
    drop_table :coupons_subscription_plans
    drop_table :credit_cards
    drop_table :subscription_changes
    drop_table :subscription_plans
    drop_table :subscriptions
  end
end
