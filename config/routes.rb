Rails.application.routes.draw do

  devise_for :users, sign_out_via: [:get, :post, :delete], controllers: {
    :registrations => "users/registrations",
    :omniauth_callbacks => "users/omniauth_callbacks"
  }
  as :user do
    get 'users', :to => 'users/registrations#edit', :as => :user_root # Rails 3
  end

  root 'home#home'

  get 'sitemap.xml' => 'home#sitemap', defaults:{format: :xml}

  get 'fuzzy_find.json' => 'home#fuzzy_find', defaults:{format: :json}

  resources :comments, only: [:create, :update]

  resources :drinks do
    member do
      get :ingredients
      get :revisions
    end
  end
  
  resources :flags, only: :create

  resources :ingredients do
    collection do
      get :names
    end
  end

  resources :photos, only: [:index, :create]
  
  resources :reviews do
    collection do
      get :count
      get :next
    end
    member do
      post :vote
    end
  end

  resources :revisions, only: [:create, :show]

  resources :users, only: [:show]

  resources :votes, only: [:create]

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
