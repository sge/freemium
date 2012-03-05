class CreateSubscriptions < ActiveRecord::Migration
  def self.up
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
    drop_table :subscriptions
  end
end
