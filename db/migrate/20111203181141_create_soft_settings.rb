class CreateSoftSettings < ActiveRecord::Migration
  def self.up
    create_table "soft_settings", :force => true do |t|
      t.integer  "user_id"
      t.string   "key"
      t.string   "value"
      t.datetime "created_at"
      t.datetime "updated_at"
    end
  end

  def self.down
    drop_table :soft_settings
  end
end
