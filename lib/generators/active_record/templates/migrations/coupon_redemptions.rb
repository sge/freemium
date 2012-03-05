class CreateCouponRedemptions < ActiveRecord::Migration
  def self.up

    create_table :coupon_redemptions, :force => true do |t|
      t.column :subscription_id, :integer, :null => false
      t.column :coupon_id, :integer, :null => false
      t.column :redeemed_on, :date, :null => false
      t.column :expired_on, :date, :null => true
    end

    add_index :coupon_redemptions, :subscription_id

  end

  def self.down
    drop_table :coupon_redemptions
  end
end
