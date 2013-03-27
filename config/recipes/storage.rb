namespace :storage do
  desc "Create a directory for storing image and other data files"
  task :setup, roles: :app do
    run "mkdir -m 700 -p #{shared_path}/data"
  end
  after "deploy:setup", "storage:setup"

  desc "Link the data directory into the the current application path"
  task :symlink, roles: :app do
    run "ln -nfs #{shared_path}/data #{current_path}"
  end
  after "deploy:update", "storage:symlink"
end
