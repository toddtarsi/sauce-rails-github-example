# frozen_string_literal: true

ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../config/environment', __dir__)
require 'capybara/rails'
require 'capybara'
require 'capybara/rspec'
require 'selenium-webdriver'
require 'rspec'

Capybara.default_max_wait_time = 10

RSpec.configure do |config|
  config.include Capybara::DSL
  config.include Capybara::RSpecMatchers

  config.before do |test|
    # Configure the server host
    Capybara.server_host = '0.0.0.0'
    # Configure the server port
    Capybara.server_port = 3001
    Capybara.app_host = 'http://localhost:3001'
    Capybara.register_driver :sauce do |app|
      url = "https://#{ENV['SAUCE_USERNAME']}:#{ENV['SAUCE_ACCESS_KEY']}@ondemand.us-west-1.saucelabs.com:443/wd/hub"
      browser_name = ENV['BROWSER_NAME'] || 'chrome'

      options = {
        browser_name: browser_name,
        platform_name: ENV['PLATFORM_NAME'] || 'Windows 10',
        browser_version: ENV['BROWSER_VERSION'] || 'latest',
        'sauce:options': {
          name: test.full_description,
          username: ENV['SAUCE_USERNAME'],
          access_key: ENV['SAUCE_ACCESS_KEY'],
          tunnelIdentifier: ENV['SAUCE_TUNNEL_ID'],
        },
      }

      caps = Selenium::WebDriver::Remote::Capabilities.send(browser_name, options)

      Capybara::Selenium::Driver.new(
        app,
        browser: :remote,
        url: url,
        desired_capabilities: caps
      )
    end
    dont_use_sauce = ENV['USE_SAUCE'].nil?
    Capybara.current_driver = dont_use_sauce ? :selenium_chrome : :sauce
  end

  config.after do |test|
    dont_use_sauce = ENV['USE_SAUCE'].nil?
    unless dont_use_sauce
      session_id = Capybara.current_session.driver.browser.session_id
      Capybara.current_session.quit
    end
  end

  #
  # Note that this build name is specifically for Circle CI execution
  # Most CI tools have ENV variables that can be structured to provide useful build names
  #
  def build_name
    ENV['SAUCE_START_TIME'] || "Ruby-RSpec-Capybara: Local-#{Time.now.to_i}"
  end
end
