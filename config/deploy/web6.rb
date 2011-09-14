$:.unshift(File.join(ENV['rvm_path'], 'lib'))
require 'rvm/capistrano'

set :rvm_ruby_string, 'ruby-1.9.2-p290'

role :web, "web6.mgmt"
role :app, "web6.mgmt"
role :db,  "web6.mgmt", :primary => true

set :user,        "d59web"
set :use_sudo,    false
set :deploy_to,   "/data/httpd/Rails/PlexusR3"

# used by migrations:
set :rails_env, "production"
