PlexusR3::Application.routes.draw do |map|
  resources :projects

  root :to => 'projects#index'
end
