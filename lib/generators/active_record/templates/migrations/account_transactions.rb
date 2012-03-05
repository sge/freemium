class CreateAccountTransactions < ActiveRecord::Migration
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
  end

  def self.down
    drop_table :account_transactions
  end
end
