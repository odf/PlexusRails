namespace :sqlite3 do
  desc "Install sqlite3"
  task :install, roles: :app do
    run "#{sudo} apt-get -y update"
    run "#{sudo} apt-get -y install sqlite3 libsqlite3-dev"
  end
  after "deploy:install", "sqlite3:install"

  desc "Set up a blank sqlite3 database file"
  task :setup, roles: :app do
    run "mkdir -m 0755 -p #{shared_path}/db"
    run "touch #{shared_path}/db/#{db_name}"
    run "chmod 0600 #{shared_path}/db/#{db_name}"
  end
  after "deploy:setup", "sqlite3:setup"

  desc "Link the database file into the current application path"
  task :symlink, roles: :app do
    run "ln -nfs #{shared_path}/db/#{db_name} #{current_path}/db/"
  end
  after "deploy:update", "sqlite3:symlink"
end
