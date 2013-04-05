namespace :nginx do
  desc "Install latest stable release of nginx"
  task :install, roles: :web do
    if os_type == 'debian'
      run "#{sudo} add-apt-repository -y ppa:nginx/stable"
      run "#{sudo} apt-get -y update"
      run "#{sudo} apt-get -y install nginx"
    elsif os_type == 'redhat'
      template "nginx_yum_repo.erb", "/tmp/nginx.repo"
      run "#{sudo} mv /tmp/nginx.repo /etc/yum.repos.d/nginx.repo"
      run "#{sudo} yum -y install nginx"
    end
  end
  after "deploy:install", "nginx:install"

  desc "Setup nginx configuration for this application"
  task :setup, roles: :web do
    run "chmod +x $HOME" # Nginx needs permission to read static assets

    if os_type == 'redhat'
      run "#{sudo} mkdir -p /etc/nginx/sites-enabled"
      run "echo 'include /etc/nginx/sites-enabled/*;' >/tmp/nginx.conf"
      run "#{sudo} mv /tmp/nginx.conf /etc/nginx/conf.d/default.conf"
    end

    template "nginx_unicorn.erb", "/tmp/nginx_conf"
    run "#{sudo} mv /tmp/nginx_conf /etc/nginx/sites-enabled/#{application}"
    run "#{sudo} rm -f /etc/nginx/sites-enabled/default"
    restart
  end
  after "deploy:setup", "nginx:setup"
  
  %w[start stop restart].each do |command|
    desc "#{command} nginx"
    task command, roles: :web do
      run "#{sudo} service nginx #{command}"
    end
  end
end
