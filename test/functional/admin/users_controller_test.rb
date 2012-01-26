require File.expand_path(File.dirname(__FILE__) + '/../../test_helper')

class Admin::UsersControllerTest < ActionController::TestCase
  def setup
    @account = Account.create(:name => 'account')
    @user = @account.users.create(:full_name => 'John Doe', :email => 'john.doe@example.com', :password => '12345', :password_confirmation => '12345', :current_account => @account)
    @user.role = 'admin'
    @user.save
    
    login_with @user
  end
  
  test "should show index" do
    get :index
    assert_response :success
  end
  
  test "should get index with search filter" do
    get :index, :search_filter => { :query => 'john' }
    assert_response :success
    assert_equal [@user], assigns(:users)
  end
  
  test "should get index with search filter that matches nothing" do
    get :index, :search_filter => { :query => 'foo' }
    assert_response :success
    assert_equal [], assigns(:users)
  end
  
  test "should update index" do
    xhr :get, :index
    assert_response :success
  end
  
  test "should update index with search filter" do
    xhr :get, :index, :search_filter => { :query => 'john' }
    assert_response :success
    assert_equal [@user], assigns(:users)
  end
end
