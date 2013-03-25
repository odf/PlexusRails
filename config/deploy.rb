require 'bundler/capistrano'

load "config/recipes/base"
load "config/recipes/nginx"
load "config/recipes/unicorn"
#load "config/recipes/postgresql"
load "config/recipes/sqlite3"
load "config/recipes/nodejs"
load "config/recipes/rbenv"
load "config/recipes/check"

server "vagrant", :web, :app, :db, primary: true

set :user,        "vagrant"
set :application, "Plexus-I"
set :deploy_to,   "/home/#{user}/apps/#{application}"
set :deploy_via, :remote_cache
set :use_sudo,    false

set :scm, :git
set :repository, "git@github.com:odf/PlexusRails.git"
set :branch,     "master"

set :rails_env, "production" # needed by migrations?

default_run_options[:pty] = true
ssh_options[:forward_agent] = true

after "deploy", "deploy:cleanup" # keep only the last 5 releases


after 'deploy:setup', :create_extra_dirs
after 'deploy:setup', :copy_secrets

after 'deploy:update', :make_symlinks

desc "create additional shared directories during setup"
task :create_extra_dirs, :roles => :app do
  run "mkdir -m 0755 -p #{shared_path}/db"
end

desc "copy the secret configuration file to the server"
task :copy_secrets, :roles => :app do
  prompt = "Specify a secrets.rb file to copy to the server:"
  path = Capistrano::CLI.ui.ask prompt
  put File.read("#{path}"), "#{shared_path}/secrets.rb", :mode => 0600
end

task :make_symlinks, :roles => :app do
  run "ln -nfs #{shared_path}/db/* #{current_path}/db/"
  run "ln -nfs #{shared_path}/secrets.rb #{current_path}/config/initializers"  
end
