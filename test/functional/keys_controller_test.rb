require File.expand_path(File.dirname(__FILE__) + '/../test_helper')

class KeysControllerTest < ActionController::TestCase
  def setup
    @account = Account.create(:name => 'account')
    @user = @account.users.create(:full_name => 'John Doe', :email => 'john.doe@example.com', :password => '12345', :password_confirmation => '12345', :current_account => @account)
    @site = @account.sites.create(:name => 'example.com', :home_url => 'http://www.example.com', :login_url => 'http://www.example.com/login')
    @user.role = 'admin'
    @user.save
    
    login_with @user
  end
  
  test "should get empty index" do
    get :index, :account_id => @account, :site_id => @site.to_param
    assert_response :success
    assert_equal [], assigns(:keys)
  end
  
  test "should show all sites" do
    key = @site.keys.create(:username => 'johndoe', :password => 'passw0rd')
    get :index, :account_id => @account, :site_id => @site.to_param
    assert_response :success
    assert_equal [key], assigns(:keys)
  end
  
  test "should get index with search filter" do
    key = @site.keys.create(:username => 'johndoe', :password => 'passw0rd')
    get :index, :account_id => @account, :site_id => @site.to_param, :search_filter => { :query => 'example' }
    assert_response :success
    assert_equal [key], assigns(:keys)
  end
  
  test "should get index with search filter that matches nothing" do
    key = @site.keys.create(:username => 'johndoe', :password => 'passw0rd')
    get :index, :account_id => @account, :site_id => @site.to_param, :search_filter => { :query => 'foobar' }
    assert_response :success
    assert_equal [], assigns(:keys)
  end
  
  test "should update index" do
    key = @site.keys.create(:username => 'johndoe', :password => 'passw0rd')
    xhr :get, :index, :account_id => @account, :site_id => @site.to_param
    assert_response :success
    assert_equal [key], assigns(:keys)
  end
  
  test "should update index with search filter" do
    key = @site.keys.create(:username => 'johndoe', :password => 'passw0rd')
    xhr :get, :index, :account_id => @account, :site_id => @site.to_param, :search_filter => { :query => 'example' }
    assert_response :success
    assert_equal [key], assigns(:keys)
  end
  
  test "should show new" do
    get :new, :account_id => @account, :site_id => @site.to_param
    assert_response :success
  end
  
  test "should create key" do
    assert_difference 'Key.count' do
      post :create, :account_id => @account, :site_id => @site.to_param, :key => { :username => 'johndoe', :password => 'passw0rd' }
      assert_response :redirect
    end
  end
  
  test "should not create invalid key" do
    assert_no_difference 'Key.count' do
      post :create, :account_id => @account, :site_id => @site.to_param, :key => { :username => nil }
      assert_response :success
    end
  end
  
  test "should show key" do
    key = @site.keys.create(:username => 'johndoe', :password => 'passw0rd')
    get :show, :account_id => @account, :site_id => @site.to_param, :id => key.to_param
    assert_response :success
  end
  
  test "should show edit" do
    key = @site.keys.create(:username => 'johndoe', :password => 'passw0rd')
    get :edit, :account_id => @account, :site_id => @site.to_param, :id => key.to_param
    assert_response :success
  end
  
  test "should update key" do
    key = @site.keys.create(:username => 'johndoe', :password => 'passw0rd')
    post :update, :account_id => @account, :site_id => @site.to_param, :id => key.to_param, :key => { :username => 'janedoe' }
    assert_response :redirect
    assert_equal 'janedoe', key.reload.username
  end
  
  test "should not update invalid key" do
    key = @site.keys.create(:username => 'johndoe', :password => 'passw0rd')
    post :update, :account_id => @account, :site_id => @site.to_param, :id => key.to_param, :key => { :username => nil }
    assert_response :success
  end
  
  test "should destroy key" do
    key = @site.keys.create(:username => 'johndoe', :password => 'passw0rd')
    assert_difference 'Key.count', -1 do
      delete :destroy, :account_id => @account, :site_id => @site.to_param, :id => key.to_param
      assert_response :redirect
    end
  end
end
