require File.expand_path(File.dirname(__FILE__) + '/../test_helper')

class FooterLinkTest < ActiveSupport::TestCase
  test "should validate" do
    assert ! FooterLink.new.valid?
    assert   FooterLink.new(:text => 'Hello', :url => 'http://www.wikipedia.org').valid?
  end
end
