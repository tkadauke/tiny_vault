module Role::Account::User
  include Role::Base
  
  allow :create_sites, :edit_sites, :delete_sites,
        :create_keys, :edit_keys, :delete_keys
end
