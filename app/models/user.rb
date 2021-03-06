class User < ActiveRecord::Base
  acts_as_authentic
  
  has_many :soft_settings
  has_many :user_accounts
  has_many :accounts, :through => :user_accounts
  has_many :config_options
  
  has_many :keys
  
  has_many :memberships
  has_many :groups, :through => :memberships
  
  belongs_to :current_account, :class_name => 'Account'
  
  validates_presence_of :full_name
  
  attr_protected :role
  
  after_initialize :extend_role
  
  def extend_role
    if self.role.blank?
      extend Role::User
    else
      extend "Role::#{self.role.classify}".constantize
    end
  end
  
  def switch_to_account(account)
    update_attribute(:current_account_id, account.id)
  end
  
  def set_role_for_account(account, role)
    user_account_for(account).update_attribute(:role, role)
  end
  
  def user_account_for(account)
    UserAccount.find_by_user_id_and_account_id(self.id, account.id)
  end
  
  def deliver_password_reset_instructions!
    reset_perishable_token!
    PasswordResetsMailer.password_reset_instructions(self).deliver
  end
  
  def reset_password!(password, password_confirmation)
    # We need to check for blank password explicitly, because authlogic only performs that check on create.
    if password.blank? || password_confirmation.blank?
      errors.add(:password, I18n.t('authlogic.error_messages.password_blank'))
      return false
    else
      self.password = password
      self.password_confirmation = password_confirmation
      save
    end
  end
  
  def self.from_param!(param)
    find(param)
  end
  
  def name
    full_name
  end
  
  def config
    @config ||= User::Configuration.new(self)
  end
  
  def self.paginate_for_list(filter, options = {})
    with_search_scope(filter) do
      paginate(options.merge(:order => 'users.created_at DESC'))
    end
  end
  
  def shares_accounts_with?(user)
    # This can probably be done more efficiently
    !(self.accounts & user.accounts).empty?
  end
  
  def keys_from_account(account)
    group_ids = memberships.map(&:group_id)
    account.keys.where('group_keys.group_id' => group_ids).joins(:group_keys)
  end
  
protected
  def self.with_search_scope(filter, &block)
    conditions = filter.empty? ? nil : ['users.full_name LIKE ? OR users.email LIKE ?', "%#{filter.query}%", "%#{filter.query}%"]
    with_scope :find => { :conditions => conditions } do
      yield
    end
  end
end
