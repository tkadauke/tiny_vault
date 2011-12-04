ENV["RAILS_ENV"] = "test"
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'mocha'
require 'authlogic/test_case'

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.(yml|csv) for all tests in alphabetical order.
  #
  # Note: You'll currently still have to declare fixtures explicitly in integration tests
  # -- they do not yet inherit this setting
  fixtures :all

  # Add more helper methods to be used by all tests here...
end

class ActionController::TestCase
  setup :activate_authlogic
  
  def login_with(user)
    UserSession.create(user)
  end
  
  def logout
    UserSession.find.destroy
  end
  
  def assert_access_denied
    assert_response :redirect
    assert_equal 'You can not do that', flash[:error]
  end
end
