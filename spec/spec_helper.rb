# frozen_string_literal: true

ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../config/environment', __dir__)
require 'capybara/rails'
require 'capybara'
require 'capybara/rspec'
require 'selenium-webdriver'
require 'rspec'
require 'sauce_whisk'
require File.expand_path('./support/sauce_labs', __dir__)

Capybara.default_max_wait_time = 10

RSpec.configure do |config|
  config.include Capybara::DSL
  config.include Capybara::RSpecMatchers

  config.before do
    # Configure the server host
    Capybara.server_host = '0.0.0.0'
    # Configure the server port
    Capybara.server_port = 3001
    Capybara.app_host = 'http://localhost:3001'
    Capybara.default_driver = :sauce
  end

  #
  # Note that this build name is specifically for Circle CI execution
  # Most CI tools have ENV variables that can be structured to provide useful build names
  #
  def build_name
    ENV['SAUCE_START_TIME'] || "Ruby-RSpec-Capybara: Local-#{Time.now.to_i}"
  end
end
