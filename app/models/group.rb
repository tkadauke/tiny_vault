class Group < ActiveRecord::Base
  belongs_to :account
  
  has_many :memberships
  has_many :members, :through => :memberships, :class_name => 'User', :source => :user
  
  has_many :group_keys
  has_many :keys, :through => :group_keys

  validates_presence_of :name
  has_permalink :name

  def to_param
    permalink
  end
  
  def self.from_param!(param)
    find_by_permalink!(param)
  end
end
