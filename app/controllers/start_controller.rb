class StartController < ApplicationController
  before_filter :login_required
  active_tab :start
  
  def index
    @account = current_user.current_account
  end
end
