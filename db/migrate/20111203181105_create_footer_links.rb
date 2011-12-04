class CreateFooterLinks < ActiveRecord::Migration
  def self.up
    create_table "footer_links", :force => true do |t|
      t.string   "text"
      t.string   "url"
      t.integer  "position"
      t.datetime "created_at"
      t.datetime "updated_at"
    end
  end

  def self.down
    drop_table :footer_links
  end
end
