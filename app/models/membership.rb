class Membership < ActiveRecord::Base
  belongs_to :user
  belongs_to :group

  attr_accessor :email
  
  before_validation :set_user_from_email, :on => :create
  
  validates_uniqueness_of :user_id, :scope => :group_id
  
protected
  def set_user_from_email
    return if email.blank?
    
    user_from_email = User.find_by_email(self.email)
    if user_from_email.nil?
      errors.add(:email, I18n.t('activerecord.errors.models.membership.attributes.email.not_found'))
      false
    else
      self.user = user_from_email
    end
  end
end
