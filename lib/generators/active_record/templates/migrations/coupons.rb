class CreateCoupons < ActiveRecord::Migration
  def self.up

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

  end

  def self.down
    drop_table :coupons
    drop_table :coupons_subscription_plans
  end
end
