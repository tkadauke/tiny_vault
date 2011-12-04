class CreateConfigOptions < ActiveRecord::Migration
  def self.up
    create_table "config_options", :force => true do |t|
      t.integer  "user_id"
      t.string   "key"
      t.text     "value"
      t.datetime "created_at"
      t.datetime "updated_at"
    end
  end

  def self.down
    drop_table :config_options
  end
end
