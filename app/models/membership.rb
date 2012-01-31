class Membership < ActiveRecord::Base
  belongs_to :user
  belongs_to :group

  attr_accessor :email
  
  validates_uniqueness_of :user_id, :scope => :group_id
end
