PlexusR3::Application.routes.draw do
  resources :users

  resources :projects do
    resources :comments, :nested_in => 'project'
    resources :images, :nested_in => 'project'
  end

  resources :samples do
    resources :comments, :nested_in => 'sample'
    resources :images, :nested_in => 'sample'
  end

  resources :data_nodes do
    resources :comments, :nested_in => 'data_node'
    resources :images, :nested_in => 'data_node'
    member do
      put :toggle
    end
  end

  resources :imports do
    collection do
      post :data_index
    end
  end

  resources :sessions

  root :to => 'projects#index'

  match 'login', :to => 'sessions#new'
  match 'logout', :to => 'sessions#destroy'

  match 'imports', :to => 'imports#create'
  match 'samples/stored_data', :to => 'imports#data_index'

  match 'pictures', :to => proc { |env|
    params = env['rack.request.form_hash']

    sample = Sample.where(:name => params['data_spec']['sample']).first
    params['sample_id'] = sample.id
    data_node = sample.data_nodes.find(params['data_id'])
    params['data_node_id'] = data_node.id
    params['nested_in'] = 'data_node'
    params['image'] = params['picture']

    ImagesController.action(:create).call(env)
  }
end
