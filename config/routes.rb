Rails.application.routes.draw do

  devise_for :users, sign_out_via: [:get, :post, :delete], controllers: {
    :registrations => "users/registrations",
    :omniauth_callbacks => "users/omniauth_callbacks",
    :sessions => "users/sessions",
  }
  as :user do
    get 'users', :to => 'users/registrations#edit', :as => :user_root # Rails 3
    get '/user/edit(.format)', to: 'users/registrations#edit', defaults: {id: 0}
  end

  root 'home#home'

  get 'sitemap.xml' => 'home#sitemap', defaults:{format: :xml}

  get 'privacy.html' => 'home#privacy', defaults:{format: :html}

  get 'tos.html' => 'home#tos', defaults:{format: :html}

  get 'fuzzy_find.json' => 'home#fuzzy_find', defaults:{format: :json}

  get 'home/drinks.json' => 'home#drinks', defaults:{format: :json}

  resources :comments, only: [:create, :destroy] do
    member do
      post :unvote_tip
      post :vote_tip
    end
  end

  resources :drinks do
    collection do
      get :suggestions
    end
    member do
      get :ingredients
      get :revisions
    end
  end

  resources :drinks, path: 'recipe', only: [:show]

  resources :favourites, only: [:index, :create, :update, :destroy]

  resources :favourites_collections, only: [:index, :create, :update, :destroy]
  
  resources :flags, only: :create

  resources :ingredients do
    collection do
      get :names
    end
    member do
      get :revisions
    end
  end

  resources :ingredients, path: 'ingredient', only: [:show]

  resources :ingredient_revisions, only: [:create, :show]

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

  resources :users, only: [:show] do
    collection do
      get :unviewed_point_distributions
      put :viewed_point_distributions
    end
    member do
      get :trophies
    end
  end

  get '/user(.format)', to: 'users#show', defaults: {id: 0}
  get '/user/trophies(.format)', to: 'users#trophies', defaults: {id: 0}

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
