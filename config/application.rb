require File.expand_path('../boot', __FILE__)

require 'rails/all'

# If you have a Gemfile, require the gems listed there, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(:default, Rails.env) if defined?(Bundler)

module PlexusR3
  class Application < Rails::Application
    config.time_zone = 'Canberra'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # Custom directories with classes and modules you want to be autoloadable.  
    config.autoload_paths += %W(#{Rails.root}/lib)

    config.generators do |g|
      g.orm :active_record
      g.template_engine :haml
    #   g.test_framework :rspec, :fixture => true, :views => false
    #   g.fixture_replacement :machinist, :dir => "spec/factories"
    end

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = "utf-8"

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:authenticity_token, :password]
  end
end
