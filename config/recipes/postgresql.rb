set_default(:postgresql_host, "localhost")
set_default(:postgresql_user) { application }
set_default(:postgresql_password) { Capistrano::CLI.password_prompt "PostgreSQL Password: " }
set_default(:postgresql_database) { "#{application}_production" }

namespace :postgresql do
  desc "Install the latest stable release of PostgreSQL."
  task :install, roles: :db, only: {primary: true} do
    if os_type == 'debian'
      run "#{sudo} add-apt-repository -y ppa:pitti/postgresql"
      run "#{sudo} apt-get -y update"
      run "#{sudo} apt-get -y install postgresql libpq-dev"
    elsif os_type == 'redhat'
      # Install postgresql
      run "#{sudo} yum -y install postgresql-server postgresql-devel"

      # Initialize and start the service, and make it start on reboot
      run "#{sudo} service postgresql initdb"
      run "#{sudo} service postgresql start"
      run "#{sudo} chkconfig --add postgresql"
      run "#{sudo} chkconfig postgresql on"

      # Enable password authorization
      run "#{sudo} sed '/^[^#]/ s/ident/md5/' /var/lib/pgsql/data/pg_hba.conf >/tmp/pg_hba.conf"
      run "#{sudo} chown postgres.postgres /tmp/pg_hba.conf"
      run "#{sudo} chmod 600 /tmp/pg_hba.conf"
      run "#{sudo} mv /tmp/pg_hba.conf /var/lib/pgsql/data/pg_hba.conf"
    end
  end
  after "deploy:install", "postgresql:install"

  desc "Create a database for this application."
  task :create_database, roles: :db, only: {primary: true} do
    run %Q{#{sudo} sudo -u postgres psql -c "create user #{postgresql_user} with password '#{postgresql_password}';"}
    run %Q{#{sudo} sudo -u postgres psql -c "create database #{postgresql_database} owner #{postgresql_user};"}
  end
  after "deploy:setup", "postgresql:create_database"

  desc "Generate the database.yml configuration file."
  task :setup, roles: :app do
    run "mkdir -p #{shared_path}/config"
    template "postgresql.yml.erb", "#{shared_path}/config/database.yml"
  end
  after "deploy:setup", "postgresql:setup"

  desc "Symlink the database.yml file into latest release"
  task :symlink, roles: :app do
    run "ln -nfs #{shared_path}/config/database.yml #{release_path}/config/database.yml"
  end
  after "deploy:finalize_update", "postgresql:symlink"
end
