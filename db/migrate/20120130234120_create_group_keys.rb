class CreateGroupKeys < ActiveRecord::Migration
  def self.up
    create_table :group_keys do |t|
      t.integer :group_id
      t.integer :key_id
      t.timestamps
    end
  end

  def self.down
    drop_table :group_keys
  end
end
