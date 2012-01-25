class Account < ActiveRecord::Base
  validates_presence_of :name
  
  has_many :user_accounts
  has_many :users, :through => :user_accounts
  
  has_many :sites
  has_many :keys, :through => :sites
  
  scope :ordered_by_name, :order => 'name ASC'
  
  def self.from_param!(param)
    find(param)
  end
  
  def user_accounts_with_users
    # RAILS BUG: This does not work here ... :order => 'users.full_name ASC')
    user_accounts.find(:all, :include => :user)
  end

  def self.paginate_for_list(filter, options = {})
    with_search_scope(filter) do
      paginate(options.merge(:order => 'accounts.name ASC'))
    end
  end
  
protected
  def self.with_search_scope(filter, &block)
    conditions = filter.empty? ? nil : ['accounts.name LIKE ?', "%#{filter.query}%"]
    with_scope :find => { :conditions => conditions } do
      yield
    end
  end
end
