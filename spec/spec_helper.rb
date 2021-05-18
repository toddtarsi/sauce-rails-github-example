# frozen_string_literal: true
ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
require 'capybara/rails'
require 'capybara'
require 'capybara/rspec'
require 'selenium-webdriver'
require 'rspec'
require 'sauce_whisk'
require File.expand_path('./support/sauce_labs', __FILE__)

Capybara.default_max_wait_time = 10

RSpec.configure do |config|
  config.include Capybara::DSL
  config.include Capybara::RSpecMatchers

  config.before do |test|
    # Configure the server host
    Capybara.server_host = '0.0.0.0'
    # Configure the server port
    Capybara.server_port = 3001
    Capybara.app_host = "http://localhost:3001"
    dont_use_sauce = ENV['USE_SAUCE'].nil?
    unless dont_use_sauce
      Capybara.register_driver :sauce do |app|
        url = 'https://ondemand.us-west-1.saucelabs.com:443/wd/hub'
        SauceWhisk.data_center = :US_WEST

        if ENV['PLATFORM_NAME'] == 'linux' # Then Headless
          url = 'https://ondemand.us-east-1.saucelabs.com:443/wd/hub'
          SauceWhisk.data_center = :US_EAST
        end

        browser_name = ENV['BROWSER_NAME'] || 'chrome'

        options = {browser_name: browser_name,
                   platform_name: ENV['PLATFORM_NAME'] || 'Windows 10',
                   browser_version: ENV['BROWSER_VERSION'] || 'latest',
                   'sauce:options': {name: test.full_description,
                                     build: build_name,
                                     username: ENV['SAUCE_USERNAME'],
                                     access_key: ENV['SAUCE_ACCESS_KEY']}}

        caps = Selenium::WebDriver::Remote::Capabilities.send(browser_name, options)

        Capybara::Selenium::Driver.new(app,
                                       browser: :remote,
                                       url: url,
                                       desired_capabilities: caps)
      end
    end
    Capybara.current_driver = dont_use_sauce ? :selenium_chrome : :sauce
  end

  config.after do |test|
    dont_use_sauce = ENV['USE_SAUCE'].nil?
    unless dont_use_sauce
      session_id = Capybara.current_session.driver.browser.session_id
      SauceWhisk::Jobs.change_status(session_id, !test.exception)
      Capybara.current_session.quit
    end
  end

  #
  # Note that this build name is specifically for Circle CI execution
  # Most CI tools have ENV variables that can be structured to provide useful build names
  #
  def build_name
    if ENV['CIRCLE_JOB']
      "#{ENV['CIRCLE_JOB']}: #{ENV['CIRCLE_BUILD_NUM']}"
    elsif ENV['SAUCE_START_TIME']
      ENV['SAUCE_START_TIME']
    else
      "Ruby-RSpec-Capybara: Local-#{Time.now.to_i}"
    end
  end
end