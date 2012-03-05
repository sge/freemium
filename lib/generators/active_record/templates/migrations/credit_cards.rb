class CreateCreditCards < ActiveRecord::Migration
  def self.up
    create_table :credit_cards, :force => true do |t|
      t.column :display_number, :string, :null => false
      t.column :card_type, :string, :null => false
      t.column :expiration_date, :timestamp, :null => false
      t.column :zip_code, :string, :null => true
    end
  end

  def self.down
    drop_table :credit_cards
  end
end
