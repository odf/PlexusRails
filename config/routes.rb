PlexusR3::Application.routes.draw do |map|
  resources :users
  resources :projects do
    resources :comments
    resources :imports do
      collection do
        post :data_index
      end
    end
    resources :data_nodes do
      resources :comments
      member do
        put :toggle
      end
    end
  end

  resources :sessions

  root :to => 'projects#index'

  match 'login' => 'sessions#new'
  match 'logout' => 'sessions#destroy'

  match 'imports' => 'imports#create'
  match 'samples/stored_data' => 'imports#data_index'
end
