class CreateKeyImports < ActiveRecord::Migration
  def self.up
    create_table :key_imports do |t|
      t.integer :account_id
      t.integer :user_id
      t.string :description
      t.text :csv_data
      t.timestamps
    end
  end

  def self.down
    drop_table :key_imports
  end
end
