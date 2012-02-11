class GroupKey < ActiveRecord::Base
  belongs_to :key
  belongs_to :group
  
  validates_presence_of :key_id, :group_id
  validates_uniqueness_of :group_id, :scope => :key_id
end
