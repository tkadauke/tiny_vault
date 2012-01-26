require File.expand_path(File.dirname(__FILE__) + '/../../test_helper')

class Role::LockedTest < ActiveSupport::TestCase
  class TestLockedAccount
    include Role::Account::Admin
  end
  
  class TestLocked
    include Role::Locked
    def id
      42
    end
  end
  
  def setup
    @user = TestLocked.new
  end
  
  test "should be able to see own profile" do
    assert @user.can_see_profile?(@user)
  end
  
  test "should not be able to see another profile" do
    assert ! @user.can_see_profile?(TestLocked.new)
  end
  
  test "should not be able to edit own profile" do
    assert ! @user.can_edit_profile?(@user)
  end
  
  test "should be able to see assigned accounts" do
    @user.expects(:user_account_for).returns(TestLockedAccount.new)
    assert @user.can_see_account?(stub(:id => 17))
  end
  
  test "should not be able see an unassigned account" do
    @user.expects(:user_account_for).returns(nil)
    assert ! @user.can_see_account?(stub(:id => 17))
  end
  
  test "should not be able to do anything else" do
    assert ! @user.can_do_whatever_he_wants?
  end
end
