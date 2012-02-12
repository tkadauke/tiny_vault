TinyVault::Application.routes.draw do
  namespace :admin do
    resources :footer_links do
      collection do
        post :sort
      end
    end
    resources :accounts
    resources :users
  end
  
  match 'admin', :to => 'admin#index', :via => :get
  
  resources :accounts do
    member do
      post :switch
    end
    resources :sites do
      resources :keys do
        resources :group_keys
      end
    end
    
    resources :groups do
      resources :memberships
    end
    resources :user_accounts
  end
  
  match 'keys/fill', :via => :get
  
  resources :key_imports
  
  resources :sites
  resources :keys do
    collection do
      post :edit_multiple
      put :update_multiple
    end
  end
  resources :groups
  
  resources :users
  resources :password_resets
  resource :settings
  
  match 'login', :to => 'user_sessions#new', :via => :get
  match 'login', :to => 'user_sessions#create', :via => :post
  match 'logout', :to => 'user_sessions#destroy', :via => :delete
  
  root :to => "start#index", :via => :get
end
