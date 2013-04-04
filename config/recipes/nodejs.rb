namespace :nodejs do
  desc "Install the latest relase of Node.js"
  task :install, roles: :app do
    if os_type == 'debian'
      run "#{sudo} add-apt-repository -y ppa:chris-lea/node.js"
      run "#{sudo} apt-get -y update"
      run "#{sudo} apt-get -y install nodejs"
    elsif os_type == 'redhat'
      name = "node-v0.10.3-linux-x86"
      run "wget http://nodejs.org/dist/v0.10.3/#{name}.tar.gz"
      run "tar xzf #{name}.tar.gz"
      run "rm -f #{name}.tar.gz"
      run "mkdir -p bin"
      run "ln -nfs $HOME/#{name}/bin/node $HOME/bin/node"
    end
  end
  after "deploy:install", "nodejs:install"
end
