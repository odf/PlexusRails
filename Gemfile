source 'https://rubygems.org'

gem 'rails', '~> 3.2.0'

group :test, :development do
  gem 'thin'
  gem 'sqlite3'
  gem 'mysql2'
end

gem 'unicorn'
gem 'pg'

group :assets do
  gem 'sass-rails', '~> 3.2.3'
  gem 'coffee-rails', '~> 3.2.1'
  gem 'uglifier', '>=1.0.3'
end

gem 'jquery-rails'

gem 'simple_form'
gem 'haml'
gem 'RedCloth'
gem 'capistrano'

# -- Testing support

gem 'rspec-rails', :group => [:test, :development]

group :test do
  gem 'capybara', '~> 1.1.4' # Need to support Ruby 1.8.7, so capybara 2 is out
  gem 'machinist'
  gem 'ffaker'
  gem 'launchy'
  gem 'simplecov', :require => false
end
