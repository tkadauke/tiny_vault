require File.expand_path(File.dirname(__FILE__) + '/../test_helper')

class ApplicationControllerTest < ActionController::TestCase
  class TestController < ApplicationController
    before_filter :login_required, :only => :user_only_action
    before_filter :guest_required, :only => :guest_only_action
    def guest_only_action
      render :text => 'foo'
    end
    def user_only_action
      render :text => 'foo'
    end
    def action
      render :text => 'foo'
    end
  end
  
  self.controller_class = TestController
  
  def with_test_routing
    with_routing do |map|
      map.draw do
        match 'application_controller_test/test/guest_only_action'
        match 'application_controller_test/test/user_only_action'
        match 'application_controller_test/test/action'
        match 'login', :to => 'user_sessions#new', :via => :get
        root :to => 'start#index'
      end
      yield
    end
  end
  
  def setup
    @account = Account.create(:name => 'account')
    @user = @account.users.create(:full_name => 'John Doe', :email => 'john.doe@example.com', :password => '12345', :password_confirmation => '12345', :current_account => @account)
    
    logout
  end

  test "should report error on guest only action for logged in user" do
    login_with @user
    
    with_test_routing do
      get :guest_only_action
      assert_response :redirect
      assert_not_nil flash[:error]
    end
  end

  test "should report error on user only action for guest" do
    with_test_routing do
      get :user_only_action
      assert_response :redirect
      assert_not_nil flash[:error]
    end
  end
end
