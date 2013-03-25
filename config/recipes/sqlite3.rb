namespace :sqlite3 do
  desc "Install sqlite3"
  task :install, roles: :app do
    run "#{sudo} apt-get -y update"
    run "#{sudo} apt-get -y install sqlite3 libsqlite3-dev"
  end
  after "deploy:install", "sqlite3:install"
end
