require File.expand_path(File.dirname(__FILE__) + '/../../test_helper')

class Admin::AccountsControllerTest < ActionController::TestCase
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
    get :index, :search_filter => { :query => 'acc' }
    assert_response :success
    assert_equal [@account], assigns(:accounts)
  end
  
  test "should get index with search filter that matches nothing" do
    get :index, :search_filter => { :query => 'foo' }
    assert_response :success
    assert_equal [], assigns(:accounts)
  end
  
  test "should update index" do
    xhr :get, :index
    assert_response :success
  end
  
  test "should update index with search filter" do
    xhr :get, :index, :search_filter => { :query => 'acc' }
    assert_equal [@account], assigns(:accounts)
    assert_response :success
  end
  
  test "should show account" do
    get :show, :id => @account
    assert_response :success
  end
  
  test "should show edit" do
    get :edit, :id => @account
    assert_response :success
  end
  
  test "should update account" do
    post :update, :id => @account, :account => { :name => 'test' }
    assert_response :redirect
    assert_equal 'test', @account.reload.name
  end
  
  test "should not update invalid account" do
    post :update, :id => @account, :account => { :name => nil }
    assert_response :success
  end
end
