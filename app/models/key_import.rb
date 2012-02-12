class KeyImport < ActiveRecord::Base
  class Row
    attr_reader :site_name, :site_description, :home_url, :login_url, :description, :username, :password
    
    def initialize(csv_row)
      @site_name, @site_description, @home_url, @login_url, @description, @username, @password = *csv_row
    end
    
    def create!(key_import)
      site = Site.find_or_create_by_account_id_and_name(:account_id => key_import.account.id, :name => @site_name, :description => @site_description, :home_url => @home_url, :login_url => @login_url)
      site.keys.create(:key_import => key_import, :user => key_import.user, :description => @description, :username => @username, :password => @password)
    end
  end
  
  belongs_to :account
  belongs_to :user
  
  has_many :keys, :dependent => :destroy
  
  after_create :import
  
  def self.fields
    [
      I18n.t("key_import.fields.site_name"),
      I18n.t("key_import.fields.site_description"),
      I18n.t("key_import.fields.home_url"),
      I18n.t("key_import.fields.login_url"),
      I18n.t("key_import.fields.description"),
      I18n.t("key_import.fields.username"),
      I18n.t("key_import.fields.password")
    ]
  end
  
  def self.from_param!(param)
    find(param)
  end
  
  def rows
    @rows ||= FasterCSV.parse(csv_data).collect { |row| Row.new(row) }
  end
  
  def import
    rows.each { |row| row.create!(self) }
  end
end
