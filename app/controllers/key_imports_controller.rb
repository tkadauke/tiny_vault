class KeyImportsController < ApplicationController
  before_filter :login_required
  before_filter :find_account
  before_filter :can_import_keys!
  
  def index
    @key_imports = @account.key_imports
  end
  
  def new
    @key_import = @account.key_imports.build
  end
  
  def create
    @key_import = @account.key_imports.build(params[:key_import])
    @key_import.user = current_user
    if params[:commit] == I18n.t("key_imports.form.preview")
      @preview = true
      render :action => 'new'
    else
      @key_import.save
      redirect_to key_import_path(@key_import)
    end
  end
  
  def show
    @key_import = @account.key_imports.find(params[:id])
    @search_filter = SearchFilter.new
  end
  
  def destroy
    @key_import = @account.key_imports.find(params[:id])
    @key_import.destroy
    redirect_to key_imports_path
  end
end
