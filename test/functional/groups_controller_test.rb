require File.expand_path(File.dirname(__FILE__) + '/../test_helper')

class GroupsControllerTest < ActionController::TestCase
  def setup
    @account = Account.create(:name => 'account')
    @user = @account.users.create(:full_name => 'John Doe', :email => 'john.doe@example.com', :password => '12345', :password_confirmation => '12345', :current_account => @account)
    @user.role = 'admin'
    @user.save
  end
  
  test "should require login" do
    logout
    
    get :index
    assert_login_required
  end
  
  test "should show index without groups" do
    get :index
    assert_response :success
  end
  
  test "should show index with groups" do
    @group = @account.groups.create(:name => 'everybody')
    get :index
    assert_response :success
  end
  
  test "should show new form" do
    get :new
    assert_response :success
  end
  
  test "should not show new form if user is not authorized" do
    @user.role = ''
    @user.save
    
    get :new
    assert_access_denied
  end
  
  test "should create group" do
    assert_difference 'Group.count' do
      post :create, :group => { :name => 'everybody' }
      assert_not_nil flash[:notice]
      assert_response :redirect
    end
  end
  
  test "should not create invalid group" do
    assert_no_difference 'Group.count' do
      post :create, :group => { :name => nil }
      assert_nil flash[:notice]
      assert_response :success
    end
  end
  
  test "should not create group if user is not authorized" do
    @user.role = ''
    @user.save
    
    post :create, :group => { :name => 'everybody' }
    assert_access_denied
  end
  
  test "should show group" do
    @group = @account.groups.create(:name => 'everybody')
    get :show, :id => @group.to_param
    assert_response :success
  end
  
  test "should not show non-existing group" do
    assert_raise ActiveRecord::RecordNotFound do
      get :show, :id => 17
    end
  end
  
  test "should show edit" do
    @group = @account.groups.create(:name => 'everybody')
    get :edit, :id => @group.to_param
    assert_response :success
  end
  
  test "should not show edit for non-existing group" do
    assert_raise ActiveRecord::RecordNotFound do
      get :edit, :id => 17
    end
  end
  
  test "should not show edit if user is not authorized" do
    @group = @account.groups.create(:name => 'everybody')
    
    @user.role = ''
    @user.save
    
    post :create, :group => { :name => 'everybody' }
    assert_access_denied
  end
  
  test "should update group" do
    @group = @account.groups.create(:name => 'everybody')
    
    put :update, :id => @group.to_param, :group => { :name => 'nobody' }
    assert_response :redirect
    assert_not_nil flash[:notice]
  end
  
  test "should not update invalid group" do
    @group = @account.groups.create(:name => 'everybody')
    
    put :update, :id => @group.to_param, :group => { :name => nil }
    assert_response :success
    assert_nil flash[:notice]
  end
  
  test "should not update non-existing group" do
    assert_raise ActiveRecord::RecordNotFound do
      put :update, :id => 17, :group => { :name => 'nobody' }
    end
  end
  
  test "should not update group if user is not authorized" do
    @user.role = ''
    @user.save

    @group = @account.groups.create(:name => 'everybody')
    put :update, :id => @group.to_param, :group => { :name => 'nobody' }
    assert_access_denied
  end
  
  test "should destroy group" do
    @group = @account.groups.create(:name => 'everybody')
    
    assert_difference 'Group.count', -1 do
      delete :destroy, :id => @group.to_param
      assert_response :redirect
    end
  end
  
  test "should not destroy non-existing group" do
    assert_raise ActiveRecord::RecordNotFound do
      delete :destroy, :id => 17
    end
  end
  
  test "should not destroy group if user is not authorized" do
    @user.role = ''
    @user.save

    @group = @account.groups.create(:name => 'everybody')
    delete :destroy, :id => @group.to_param
    assert_access_denied
  end
end
