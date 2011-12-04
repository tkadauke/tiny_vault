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
      resources :logins do
        collection do
          post :edit_multiple
          put :update_multiple
        end
      end
    end
    
    resources :user_accounts
  end
  
  match 'logins/fill', :via => :get
  
  resources :sites
  
  resources :users
  resources :password_resets
  resource :settings
  
  match 'login', :to => 'user_sessions#new', :via => :get
  match 'login', :to => 'user_sessions#create', :via => :post
  match 'logout', :to => 'user_sessions#destroy', :via => :delete
  
  root :to => "start#index", :via => :get
end
