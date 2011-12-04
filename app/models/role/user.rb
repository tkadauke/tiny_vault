module Role::User
  include Role::Base
  
  def can_see_profile?(user)
    user == self || self.shares_accounts_with?(user)
  end
  
  def can_edit_profile?(user)
    user == self
  end
  
  def can_switch_to_account?(account)
    !user_account_for(account).nil?
  end
  
  alias_method :can_see_account?, :can_switch_to_account?
  
  def self.delegate_to_account(*permissions)
    permissions.each do |permission|
      define_method "can_#{permission}?" do |account|
        user_account_for(account).send("can_#{permission}?")
      end
    end
  end
  
  delegate_to_account :edit_account, :add_user_to_account,
                      :create_sites, :edit_sites, :delete_sites
  
  def can_remove_user_from_account?(user, account)
    user != self && can_add_user_to_account?(account)
  end
  
  def can_assign_role_for_user_and_account?(user, account)
    user != self && can_add_user_to_account?(account)
  end
  
  def can_edit_login_template?(template)
    self == template.user || user_account_for(template.account).can_edit_login_template?
  end
  
  allow :edit_settings, :see_account_details
end
