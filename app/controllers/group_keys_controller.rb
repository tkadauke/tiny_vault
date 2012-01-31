class GroupKeysController < ApplicationController
  before_filter :login_required
  before_filter :find_account
  before_filter :find_site
  before_filter :find_key
  
  def create
    can_add_key_to_group!(@key, @group) do
      @group_key = @key.group_keys.build(params[:group_key])
      if @group_key.save
        flash[:notice] = I18n.t('flash.notice.created_group_key')
      else
        flash[:error] = I18n.t('flash.error.could_not_create_group_key')
      end
      redirect_to account_site_key_path(@account, @site, @key)
    end
  end
  
  def destroy
    @group_key = @key.group_keys.find(params[:id])
    can_remove_key_from_group!(@key, @group) do
      @group_key.destroy
      flash[:notice] = I18n.t('flash.notice.removed_group_key')
      redirect_to account_site_key_path(@account, @site, @key)
    end
  end

protected
  def find_site
    @site = @account.sites.find_by_permalink!(params[:site_id])
  end
  
  def find_key
    @key = @site.keys.find(params[:key_id])
  end
end
