require File.expand_path(File.dirname(__FILE__) + '/../test_helper')

class MembershipsControllerTest < ActionController::TestCase
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
    
    post :create, :account_id => @account, :site_id => @site.to_param, :group_id => @group.to_param, :membership => { :user_id => @user }
    assert_login_required
  end
  
  test "should create membership" do
    login_with @user
    
    assert_difference 'Membership.count' do
      post :create, :account_id => @account, :site_id => @site.to_param, :group_id => @group.to_param, :membership => { :user_id => @user }
      assert_not_nil flash[:notice]
      assert_response :redirect
    end
  end
  
  test "should not create invalid membership" do
    login_with @user
    
    assert_no_difference 'Membership.count' do
      post :create, :account_id => @account, :site_id => @site.to_param, :group_id => @group.to_param, :membership => { :user_id => nil }
      assert_not_nil flash[:error]
      assert_response :redirect
    end
  end
  
  test "should not create membership if user is not authorized" do
    @user.role = ''
    @user.save
    
    assert_no_difference 'Membership.count' do
      post :create, :account_id => @account, :site_id => @site.to_param, :group_id => @group.to_param, :membership => { :user_id => nil }
      assert_not_nil flash[:error]
      assert_access_denied
    end
  end
  
  test "should destroy membership" do
    login_with @user
    @membership = Membership.create(:group => @group, :user => @user)
    
    assert_difference 'Membership.count', -1 do
      delete :destroy, :account_id => @account, :site_id => @site.to_param, :group_id => @group.to_param, :id => @membership
      assert_not_nil flash[:notice]
      assert_response :redirect
    end
  end
  
  test "should not destroy non-existing membership" do
    login_with @user
    
    assert_raise ActiveRecord::RecordNotFound do
      delete :destroy, :account_id => @account, :site_id => @site.to_param, :group_id => @group.to_param, :id => 17
    end
  end
  
  test "should not destroy membership if user is not authorized" do
    @user.role = ''
    @user.save
    @membership = Membership.create(:group => @group, :user => @user)
    
    assert_no_difference 'Membership.count' do
      delete :destroy, :account_id => @account, :site_id => @site.to_param, :group_id => @group.to_param, :id => @membership
      assert_not_nil flash[:error]
      assert_access_denied
    end
  end
end
