class CreateUserAccounts < ActiveRecord::Migration
  def self.up
    create_table "user_accounts", :force => true do |t|
      t.integer  "user_id"
      t.integer  "account_id"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "role",       :default => "user"
    end
  end

  def self.down
    drop_table :user_accounts
  end
end
