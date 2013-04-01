require 'bundler/capistrano'

load "config/recipes/base"
load "config/recipes/ssl"
load "config/recipes/nginx"
load "config/recipes/unicorn"
load "config/recipes/sqlite3"
load "config/recipes/nodejs"
load "config/recipes/rbenv"
load "config/recipes/check"
load "config/recipes/secrets"
load "config/recipes/storage"

server "vagrant", :web, :app, :db, primary: true

set :user,        "vagrant"
set :application, "Plexus-I"
set :deploy_to,   "/home/#{user}/apps/#{application}"
set :deploy_via, :remote_cache
set :use_sudo,    false

set :scm, :git
set :repository, "git@github.com:odf/PlexusRails.git"
set :branch,     "master"

set :use_https, "yes"
set :generate_self_signed_ssl_cert, "yes"
set :ssl_path, "/home/#{user}/ssl"

default_run_options[:pty] = true
ssh_options[:forward_agent] = true

after "deploy", "deploy:cleanup" # keep only the last 5 releases
