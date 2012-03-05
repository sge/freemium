class CreateSubscriptionPlans < ActiveRecord::Migration
  def self.up
    create_table :subscription_plans, :force => true do |t|
      t.column :name, :string, :null => false
      t.column :key, :string, :null => false
      t.column :rate_cents, :integer, :null => false
      t.column :feature_set_id, :string, :null => false
    end
  end

  def self.down
    drop_table :subscription_plans
  end
end
