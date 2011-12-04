require File.expand_path(File.dirname(__FILE__) + '/../../../test_helper')

class Role::Account::UserTest < ActiveSupport::TestCase
  class TestUserAccount
    include Role::Account::User
  end
  
  def setup
    @user = TestUserAccount.new
  end
  
  test "should be able to create logins" do
    assert @user.can_create_logins?
  end
  
  test "should be able to edit logins" do
    assert @user.can_edit_logins?
  end
  
  test "should be able to delete logins" do
    assert @user.can_delete_logins?
  end
  
  test "should be able to create sites" do
    assert @user.can_create_sites?
  end
  
  test "should be able to edit sites" do
    assert @user.can_edit_sites?
  end
  
  test "should be able to delete sites" do
    assert @user.can_delete_sites?
  end
  
  test "should not be able to do anything else" do
    assert ! @user.can_do_whatever_he_wants?
  end

  test "should not catch other methods" do
    assert_raise NoMethodError do
      @user.foobar
    end
  end
end
