require File.expand_path(File.dirname(__FILE__) + '/../test_helper')

class SettingsControllerTest < ActionController::TestCase
  def setup
    @account = Account.create(:name => 'account')
    @user = @account.users.create(:full_name => 'John Doe', :email => 'john.doe@example.com', :password => '12345', :password_confirmation => '12345', :current_account => @account)
  end
  
  test "should show user settings" do
    login_with @user
    
    get 'show'
    assert_response :success
  end
  
  test "should update user settings" do
    login_with @user
    
    post 'create', :config => { :language => 'de' }
    assert_not_nil flash[:notice]
    assert_response :redirect
    
    assert @user.reload.config.language
    assert_equal 'de', @user.reload.config.language
  end
end
