require File.expand_path('../boot', __FILE__)

require 'rails/all'

if defined?(Bundler)
  # If you precompile assets before deploying to production, use this line
  Bundler.require *Rails.groups(:assets => %w(development test))
  # If you want your assets lazily compiled in production, use this line
  # Bundler.require(:default, :assets, Rails.env)
end

module PlexusR3
  class Application < Rails::Application
    # Secrets could be required for database.yml, which is
    # loaded before the config/initializers directory.
    #require File.expand_path('../initializers/secrets', __FILE__)

    config.time_zone = 'Canberra'

    # Enable the asset pipeline
    config.assets.enabled = true

    # Version of your assets, change this if you want to expire all your assets  
    config.assets.version = '1.0'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # Custom directories with classes and modules you want to be autoloadable.  
    config.autoload_paths += %W(#{Rails.root}/lib)

    config.generators do |g|
      g.orm :active_record
      g.template_engine :haml
      g.test_framework :rspec #, :fixture => true, :views => false
      #g.fixture_replacement :machinist, :dir => "spec/factories"
    end

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = "utf-8"

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:authenticity_token, :password]
  end
end
