namespace :bundler do
  desc "Install bundler"
  task :install, roles: :app do
    run "#{sudo} gem install bundler --no-ri --no-rdoc"
  end
  after "deploy:install", "bundler:install"
end
