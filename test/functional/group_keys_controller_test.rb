require File.expand_path(File.dirname(__FILE__) + '/../test_helper')

class GroupKeysControllerTest < ActionController::TestCase
  def setup
    @account = Account.create(:name => 'account')
    @user = @account.users.create(:full_name => 'John Doe', :email => 'john.doe@example.com', :password => '12345', :password_confirmation => '12345', :current_account => @account)
    @site = @account.sites.create(:name => 'example.com', :home_url => 'http://www.example.com', :login_url => 'http://www.example.com/login')
    @key = @site.keys.create(:username => 'johndoe', :password => 'passw0rd')
    @group = @account.groups.create(:name => 'everybody')
    @user.role = 'admin'
    @user.save
  end
  
  test "should require login" do
    logout
    
    post :create, :account_id => @account, :site_id => @site.to_param, :key_id => @key, :group_key => { :group_id => @group }
    assert_login_required
  end
  
  test "should create group key" do
    login_with @user
    
    assert_difference 'GroupKey.count' do
      post :create, :account_id => @account, :site_id => @site.to_param, :key_id => @key, :group_key => { :group_id => @group }
      assert_not_nil flash[:notice]
      assert_response :redirect
    end
  end
  
  test "should not create invalid group key" do
    login_with @user
    
    assert_no_difference 'GroupKey.count' do
      post :create, :account_id => @account, :site_id => @site.to_param, :key_id => @key, :group_key => { :group_id => nil }
      assert_not_nil flash[:error]
      assert_response :redirect
    end
  end
  
  test "should not create group key if user is not authorized" do
    @user.role = ''
    @user.save
    
    assert_no_difference 'GroupKey.count' do
      post :create, :account_id => @account, :site_id => @site.to_param, :key_id => @key, :group_key => { :group_id => nil }
      assert_not_nil flash[:error]
      assert_access_denied
    end
  end
  
  test "should destroy group key" do
    login_with @user
    @group_key = GroupKey.create(:group => @group, :key => @key)
    
    assert_difference 'GroupKey.count', -1 do
      delete :destroy, :account_id => @account, :site_id => @site.to_param, :key_id => @key, :id => @group_key
      assert_not_nil flash[:notice]
      assert_response :redirect
    end
  end
  
  test "should not destroy non-existing group key" do
    login_with @user
    
    assert_raise ActiveRecord::RecordNotFound do
      delete :destroy, :account_id => @account, :site_id => @site.to_param, :key_id => @key, :id => 17
    end
  end
  
  test "should not destroy group key if user is not authorized" do
    @user.role = ''
    @user.save
    @group_key = GroupKey.create(:group => @group, :key => @key)
    
    assert_no_difference 'GroupKey.count' do
      delete :destroy, :account_id => @account, :site_id => @site.to_param, :key_id => @key, :id => @group_key
      assert_not_nil flash[:error]
      assert_access_denied
    end
  end
end
