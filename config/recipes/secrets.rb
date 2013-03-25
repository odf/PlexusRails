require 'securerandom'

namespace :secrets do
  desc "Create a secret token for this deployment"
  task :setup, roles: :app do
    template "secret_token.rb.erb", "#{shared_path}/secret_token.rb"
  end
  after "deploy:setup", "secrets:setup"

  desc "Link the secret token file to the newly deployed code"
  task :symlink, roles: :app do
    run "ln -nfs #{shared_path}/secret_token.rb #{current_path}/config/initializers"
  end
  after "deploy:update", "secrets:symlink"
end
