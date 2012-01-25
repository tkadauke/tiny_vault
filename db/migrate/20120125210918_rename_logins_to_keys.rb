class RenameLoginsToKeys < ActiveRecord::Migration
  def self.up
    rename_table :logins, :keys
  end

  def self.down
    rename_table :keys, :logins
  end
end
