PlexusR3::Application.routes.draw do |map|
  resources :users
  resources :projects do
    resources :comments
  end
  resources :sessions

  root :to => 'projects#index'

  match 'login' => 'sessions#new'
  match 'logout' => 'sessions#destroy'
end
