class AddKeyImportIdToKeys < ActiveRecord::Migration
  def self.up
    add_column :keys, :key_import_id, :integer
  end

  def self.down
    remove_column :keys, :key_import_id
  end
end
