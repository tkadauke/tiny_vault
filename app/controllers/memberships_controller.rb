class MembershipsController < ApplicationController
  before_filter :login_required
  before_filter :find_account
  before_filter :find_group
  
  def create
    can_add_user_to_group!(@account) do
      @membership = @group.memberships.build(params[:membership])
      if @membership.save
        flash[:notice] = I18n.t('flash.notice.created_membership')
      else
        flash[:error] = I18n.t('flash.error.could_not_create_membership')
      end
      redirect_to account_group_path(@account, @group)
    end
  end
  
  def destroy
    @membership = @group.memberships.find(params[:id])
    can_remove_user_from_group!(@membership.user, @group) do
      @membership.destroy
      flash[:notice] = I18n.t('flash.notice.removed_member')
      redirect_to account_group_path(@account, @group)
    end
  end

protected
  def find_group
    @group = @account.groups.find_by_permalink!(params[:group_id])
  end
end
