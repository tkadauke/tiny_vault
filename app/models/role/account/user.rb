module Role::Account::User
  include Role::Base
  
  allow :create_sites, :edit_sites, :delete_sites,
        :create_logins, :edit_logins, :delete_logins
end
