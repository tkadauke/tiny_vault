class CreateGroups < ActiveRecord::Migration
  def self.up
    create_table :groups do |t|
      t.integer :account_id
      t.string :name
      t.string :permalink
      t.timestamps
    end
    
    add_index :groups, :permalink
  end

  def self.down
    drop_table :groups
  end
end
