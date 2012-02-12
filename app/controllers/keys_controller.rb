class KeysController < ApplicationController
  before_filter :login_required, :except => :fill
  before_filter :find_account, :except => :fill
  before_filter :find_site
  active_tab :keys

  def index
    @search_filter = SearchFilter.new(params[:search_filter])
    if @site
      @keys = @site.keys.find_for_list(@search_filter, :order => 'keys.username ASC')
    else
      @filter = current_user.soft_settings.get_or_set("keys.filter", params[:filter], :default => 'mine')
      
      if @filter == 'mine'
        @keys = current_user.keys.find_for_list(@search_filter, :order => 'keys.username ASC')
      else
        @keys = current_user.keys_from_account(@account).find_for_list(@search_filter, :order => 'keys.username ASC')
      end
      
      render :action => 'all_keys' unless request.xhr?
    end
    
    render :update do |page|
      page.replace_html 'keys', :partial => 'list', :locals => { :keys => @keys }
    end if request.xhr?
  end

  def fill
    respond_to do |wants|
      wants.js do
        if logged_in?
          @account = current_user.current_account
          @site = @account.sites.find_by_login_domain(params[:domain])
          if @site
            @keys = @site.keys_for_user(current_user)
            if @keys.size > 0
              render :text => "%s(%s);" % [params[:callback], @keys.to_json]
            else
              render_json_error I18n.t('keys.fill.error.no_keys_found', :account => @account.name)
            end
          else
            render_json_error I18n.t('keys.fill.error.site_not_found', :account => @account.name)
          end
        else
          render_json_error I18n.t('keys.fill.error.not_logged_in')
        end
      end
    end
  end

  def new
    can_create_keys!(@account) do
      @key = @site.keys.build
    end
  end

  def create
    can_create_keys!(@account) do
      @key = @site.keys.build(params[:key])
      @key.user = current_user
      if @key.save
        flash[:notice] = I18n.t('flash.notice.created_key', :key => @key.description)
        redirect_to account_site_keys_path(@account, @site)
      else
        render :action => 'new'
      end
    end
  end

  def show
    @key = @site.keys.find(params[:id])
  end

  def edit
    can_edit_keys!(@account) do
      @key = @site.keys.find(params[:id])
    end
  end

  def edit_multiple
    redirect_to :back and return if params[:key_ids].blank?

    can_edit_keys!(@account) do
      @keys = @account.keys.find(params[:key_ids], :include => :site, :order => 'sites.name ASC, keys.username ASC')
    end
  end

  def update
    can_edit_keys!(@account) do
      @key = @site.keys.find(params[:id])
      if @key.update_attributes(params[:key])
        flash[:notice] = I18n.t('flash.notice.updated_key', :key => @key.description || @key.username)
        redirect_to account_site_key_path(@account, @site, @key)
      else
        render :action => 'edit'
      end
    end
  end

  def update_multiple
    can_edit_keys!(@account) do
      @keys = @account.keys.readonly(false).find(params[:key_ids])
      updated = @keys.map do |key|
        key.bulk_update(params[:key])
      end

      flash[:notice] = I18n.t("flash.notice.bulk_updated_keys", :count => updated.count(true))
      redirect_to keys_path
    end
  end

  def destroy
    can_delete_keys!(@account) do
      @key = @site.keys.find(params[:id])
      @key.destroy
      flash[:notice] = I18n.t('flash.notice.deleted_key', :key => @key.description || @key.username)
      redirect_to account_site_keys_path(@account, @site)
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
