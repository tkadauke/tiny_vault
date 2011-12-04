class LoginsController < ApplicationController
  before_filter :login_required, :except => :fill
  before_filter :find_account, :except => :fill
  before_filter :find_site
  active_tab :sites

  def index
    @search_filter = SearchFilter.new(params[:search_filter])
    @logins = @site.logins.find_for_list(@search_filter, @status, :order => 'logins.username ASC')
  end

  def fill
    respond_to do |wants|
      wants.js do
        if logged_in?
          @account = current_user.current_account
          @site = @account.sites.find_by_login_domain(params[:domain])
          if @site
            render :text => "%s(%s);" % [params[:callback], @site.logins.to_json]
          else
            render_json_error I18n.t('logins.fill.error.site_not_found', :account => @account.name)
          end
        else
          render_json_error I18n.t('logins.fill.error.not_logged_in')
        end
      end
    end
  end

  def new
    can_create_logins!(@account) do
      @login = @site.logins.build
    end
  end

  def create
    can_create_logins!(@account) do
      @login = @site.logins.build(params[:login])
      if @login.save
        flash[:notice] = I18n.t('flash.notice.created_login', :login => @login.description)
        redirect_to account_site_logins_path(@account, @site)
      else
        render :action => 'new'
      end
    end
  end

  def show
    @login = @site.logins.find(params[:id])
  end

  def edit
    can_edit_logins!(@account) do
      @login = @site.logins.find(params[:id])
    end
  end

  def edit_multiple
    redirect_to :back and return if params[:login_ids].blank?

    can_edit_logins!(@account) do
      @logins = @account.logins.find(params[:login_ids], :include => :site, :order => 'sites.name ASC, logins.username ASC')
    end
  end

  def update
    can_edit_logins!(@account) do
      @login = @site.logins.find(params[:id])
      if @login.update_attributes(params[:login])
        flash[:notice] = I18n.t('flash.notice.updated_login', :login => @login.name)
        redirect_to account_site_login_path(@account, @site, @login)
      else
        render :action => 'edit'
      end
    end
  end

  def update_multiple
    can_edit_logins!(@account) do
      @logins = @account.logins.find(params[:login_ids])
      updated = @logins.map do |login|
        login.bulk_update(params[:login])
      end

      flash[:notice] = I18n.t("flash.notice.bulk_updated_logins", :count => updated.count(true))
      redirect_to logins_path
    end
  end

  def destroy
    can_delete_logins!(@account) do
      @login = @site.logins.find(params[:id])
      @login.destroy
      flash[:notice] = I18n.t('flash.notice.deleted_login', :login => @login.name)
      redirect_to account_site_logins_path(@account, @site)
    end
  end

protected
  def find_site
    @site = @account.sites.find_by_permalink!(params[:site_id]) if params[:site_id]
  end
  
  def render_json_error(error)
    render :text => "%s(%s);" % [params[:callback], { :error => error }.to_json]
  end
end
