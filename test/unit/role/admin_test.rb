require File.expand_path(File.dirname(__FILE__) + '/../../test_helper')

class Role::AdminTest < ActiveSupport::TestCase
  class TestAdmin
    include Role::Admin
    def id
      42
    end
  end
  
  def setup
    @user = TestAdmin.new
  end
  
  test "should forward unrecognized calls to parent class" do
    assert_raise NoMethodError do
      @user.foobar
    end
  end
  
  test "should be able to do anything else" do
    assert @user.can_do_whatever_he_wants?
  end
end
