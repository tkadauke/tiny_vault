class SoftSetting < ActiveRecord::Base
  belongs_to :user
  
  def self.get(key, options = {})
    find_by_key(key).value rescue options[:default]
  end
  
  def self.set(key, value)
    find_or_create_by_key(key).update_attribute(:value, value)
    value
  end
  
  def self.unset(key)
    find_by_key(key).destroy rescue nil
  end
  
  def self.get_or_set(key, value, options = {})
    if value
      set(key, value)
    else
      get(key, options)
    end
  end
end
