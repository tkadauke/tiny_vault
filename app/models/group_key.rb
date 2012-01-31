class GroupKey < ActiveRecord::Base
  belongs_to :key
  belongs_to :group
end
