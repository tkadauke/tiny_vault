require File.expand_path(File.dirname(__FILE__) + '/../test_helper')

class AccountTest < ActiveSupport::TestCase
  test "should validate" do
    assert ! Account.new.valid?
    assert   Account.new(:name => 'some name').valid?
  end

  test "should find plan by id" do
    Account.expects(:find).with(1)
    Account.from_param!(1)
  end
  
  test "should find user account with users" do
    account = Account.new
    account.user_accounts.expects(:find).with(:all, has_entry(:include => :user))
    account.user_accounts_with_users
  end
  
  test "should apply filter when paginating" do
    Account.expects(:with_scope).with(:find => {:conditions => ['accounts.name LIKE ?', '%filter%']})
    Account.paginate_for_list(stub(:empty? => false, :query => 'filter'))
  end
  
  test "should not apply filter when paginating if no filter is given" do
    Account.expects(:with_scope).with(:find => {:conditions => nil})
    Account.paginate_for_list(stub(:empty? => true))
  end
  
  test "should order by name when paginating" do
    Account.expects(:paginate).with(has_entry(:order => 'accounts.name ASC'))
    Account.paginate_for_list(stub(:empty? => true))
  end
  
  test "should forward find options when paginating" do
    Account.expects(:paginate).with(has_entry(:foo => 'bar'))
    Account.paginate_for_list(stub(:empty? => true), :foo => 'bar')
  end
end
