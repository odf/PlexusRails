PlexusR3::Application.routes.draw do |map|
  resources :users

  resources :projects

  root :to => 'projects#index'
end
