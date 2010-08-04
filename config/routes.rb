PlexusR3::Application.routes.draw do |map|
  resources :users
  resources :projects do
    resources :comments, :nested_in => 'project'
    resources :imports do
      collection do
        post :data_index
      end
    end
    resources :data_nodes do
      resources :comments, :nested_in => 'data_node'
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

  # -- quick test for picture uploading
  match 'pictures' => proc { |env|
    params =  env['rack.request.form_hash']
    payload = params['picture']['uploaded_data']
    name = payload[:filename]
    data = payload[:tempfile].read
    File.open("/home/olaf/scratch/Plexus-files/#{name}", "w") { |fp|
      fp.write(data)
    }

    response = {
      'Status' => 'Success',
      'Name'   => name,
      'Size'   => data.size,
      'NodeID' => params['data_id']
    }

    [200, {}, [response.to_json]]
  }
end
