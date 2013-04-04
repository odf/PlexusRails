def template(from, to)
  erb = File.read(File.expand_path("../templates/#{from}", __FILE__))
  put ERB.new(erb).result(binding), to
end

def set_default(name, *args, &block)
  set(name, *args, &block) unless exists?(name)
end

namespace :deploy do
  desc "Install everything onto the server"
  task :install do
    if os_type == 'redhat'
      run "#{sudo} yum -y install curl git-core wget" 
    elsif os_type == 'debian'
      run "#{sudo} apt-get -y update"
      run "#{sudo} apt-get -y install python-software-properties curl git-core"
    end
  end
end
