set_default(:rails_env, "production")
set_default(:sqlite3_db_file, "#{rails_env}.sqlite3")

namespace :sqlite3 do
  desc "Install sqlite3"
  task :install, roles: :app do
    run "#{sudo} apt-get -y update"
    run "#{sudo} apt-get -y install sqlite3 libsqlite3-dev"
  end
  after "deploy:install", "sqlite3:install"

  desc "Set up a blank sqlite3 database file"
  task :create_database, roles: :app do
    run "mkdir -m 0755 -p #{shared_path}/db"
    run "touch #{shared_path}/db/#{sqlite3_db_file}"
    run "chmod 0600 #{shared_path}/db/#{sqlite3_db_file}"
  end
  after "deploy:setup", "sqlite3:create_database"

  desc "Generate the database.yml configuration file."
  task :setup, roles: :app do
    run "mkdir -p #{shared_path}/config"
    template "sqlite3.yml.erb", "#{shared_path}/config/database.yml"
    run "chmod 0400 #{shared_path}/config/database.yml"
  end
  after "deploy:setup", "sqlite3:setup"

  desc "Symlink the database and the configuration file into the latest release"
  task :symlink, roles: :app do
    run "ln -nfs #{shared_path}/db/#{sqlite3_db_file} #{release_path}/db/"
    run "ln -nfs #{shared_path}/config/database.yml #{release_path}/config/"
  end
  after "deploy:finalize_update", "sqlite3:symlink"
end
