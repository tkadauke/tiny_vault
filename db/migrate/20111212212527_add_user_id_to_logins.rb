class AddUserIdToLogins < ActiveRecord::Migration
  def self.up
    add_column :logins, :user_id, :integer
  end

  def self.down
    remove_column :logins, :user_id
  end
end
