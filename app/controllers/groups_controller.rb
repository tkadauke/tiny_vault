class GroupsController < ApplicationController
  before_filter :login_required
  before_filter :find_account
  active_tab :groups

  def index
    @groups = @account.groups
  end

  def new
    can_create_groups!(@account) do
      @group = @account.groups.build
    end
  end
  
  def create
    can_create_groups!(@account) do
      @group = @account.groups.build(params[:group])
      if @group.save
        flash[:notice] = I18n.t('flash.notice.created_group', :group => @group.name)
        redirect_to account_group_path(@account, @group)
      else
        render :action => 'new'
      end
    end
  end
  
  def show
    @group = @account.groups.find_by_permalink!(params[:id])
  end
  
  def edit
    can_edit_groups!(@account) do
      @group = @account.groups.find_by_permalink!(params[:id])
    end
  end
  
  def update
    can_edit_groups!(@account) do
      @group = @account.groups.find_by_permalink!(params[:id])
      if @group.update_attributes(params[:group])
        flash[:notice] = I18n.t('flash.notice.updated_group', :group => @group.name)
        redirect_to account_group_path(@account, @group)
      else
        render :action => 'edit'
      end
    end
  end
  
  def destroy
    can_delete_groups!(@account) do
      @group = @account.groups.find_by_permalink!(params[:id])
      @group.destroy
      flash[:notice] = I18n.t('flash.notice.deleted_group', :group => @group.name)
      redirect_to groups_path
    end
  end
end
