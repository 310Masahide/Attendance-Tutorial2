require_relative 'boot'

require 'rails/all'
Bundler.require(*Rails.groups)

module AttendanceApp
  class Application < Rails::Application
    config.load_defaults 5.1
    config.time_zone = 'Asia/Tokyo'
  end
end

