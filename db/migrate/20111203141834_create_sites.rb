class CreateSites < ActiveRecord::Migration
  def self.up
    create_table :sites do |t|
      t.integer :account_id
      t.string :name
      t.string :permalink
      t.string :description
      t.string :home_url
      t.string :login_url
      t.string :login_domain
      t.timestamps
    end
    
    add_index :sites, :login_domain
    add_index :sites, :permalink
  end

  def self.down
    drop_table :sites
  end
end
