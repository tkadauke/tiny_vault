class Key < ActiveRecord::Base
  belongs_to :site
  belongs_to :user
  belongs_to :key_import
  
  has_many :group_keys
  has_many :groups, :through => :group_keys
  
  validates_presence_of :site_id, :username, :password
  
  attr_accessor :add_group_id, :delete_group_id
  
  after_save :enable_or_disable_group
  
  def self.find_for_list(filter, find_options)
    with_search_scope(filter) do
      find(:all, find_options.merge(:include => {:site => :account}))
    end
  end
  
  def self.from_param!(param)
    find(param)
  end
  
  def bulk_update(attributes)
    selections = attributes.inject({}) { |hash, pair| hash[pair.first] = pair.last if pair.first =~ /^bulk_update/; hash }.with_indifferent_access
    values = attributes.inject({}) { |hash, pair| hash[pair.first] = pair.last if pair.first !~ /^bulk_update/; hash }.with_indifferent_access
    
    values.reject! { |name, v| selections["bulk_update_#{name}"] != '1' }
    
    update_attributes(values) unless values.empty?
  end

protected
  def self.with_search_scope(filter, &block)
    conditions = if filter.empty?
      nil
    else
      # See activerecord/lib/active_record/associations.rb, line 1666
      #
      # For the SQL LIKE condition, we need to get rid of dots in the filter query, because ActiveRecord thinks
      # everything left of a dot is a referenced table, which results in SQL errors (few filter queries are actual
      # table names). This has the subtle consequence that a dot in the search field matches any character in the
      # SQL result set, whereas in the frontend only actual dots get highlighted. We replace dots with underscores,
      # which match a single character in SQL LIKE queries.
      sql_like = filter.query.gsub('.', '_')
      ['keys.username LIKE ? OR sites.name LIKE ?', "%#{sql_like}%", "%#{sql_like}%"]
    end
    
    with_scope :find => { :conditions => conditions } do
      yield
    end
  end
  
  def enable_or_disable_group
    group_keys.create(:group_id => add_group_id) if add_group_id
    groups.delete(Group.find(delete_group_id)) if delete_group_id
  end
end
