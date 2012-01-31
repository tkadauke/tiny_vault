class Site < ActiveRecord::Base
  belongs_to :account
  has_many :keys
  
  before_save :set_login_domain

  has_permalink :name
  
  validates_presence_of :name, :home_url, :login_url
  
  def to_param
    permalink
  end
  
  def self.from_param!(param)
    find_by_permalink!(param)
  end
  
  def self.find_for_list(filter)
    with_search_scope(filter) do
      find(:all, :include => :account, :order => 'sites.name ASC')
    end
  end
  
  def keys_for_user(user)
    group_ids = user.memberships.map(&:group_id)
    keys.where(['user_id = ? OR group_keys.group_id in (?)', user.id, group_ids]).includes(:group_keys)
  end

protected
  def self.with_search_scope(filter, &block)
    conditions = filter.empty? ? nil : ['sites.name LIKE ?', "%#{filter.query}%"]
    with_scope :find => { :conditions => conditions } do
      yield
    end
  end

  def set_login_domain
    uri = URI.parse(login_url)
    self.login_domain = uri.host
  rescue URI::InvalidURIError
    errors.add(:login_url, 'is invalid')
  end
end
