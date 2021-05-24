# These are our hooks to configure RSpec
# Note that there is an expected environment variable of USE_SAUCE_CONNECT_IN_PROCESS=true
RSpec.configure do |config|
  config.before(:suite) do
    SauceWhisk.data_center = :US_WEST
    if env['USE_SAUCE_CONNECT_IN_PROCESS']
      @sc_worker = SauceConnectWorker.new
      @sc_worker.wait_until_ready
    end
  end
  config.after(:suite) do
    if env['USE_SAUCE_CONNECT_IN_PROCESS']
      @sc_worker&.complete
    end
  end
  config.before do |test|
    Capybara.register_driver :sauce do |app|
      url = "https://#{ENV['SAUCE_USERNAME']}:#{ENV['SAUCE_ACCESS_KEY']}@ondemand.us-west-1.saucelabs.com:443/wd/hub"
      browser_name = ENV['BROWSER_NAME'] || 'chrome'

      Capybara::Selenium::Driver.new(
        app,
        browser: :remote,
        url: url,
        desired_capabilities: Selenium::WebDriver::Remote::Capabilities.send(
          browser_name,
          browser_name: browser_name,
          platform_name: ENV['PLATFORM_NAME'] || 'Windows 10',
          browser_version: ENV['BROWSER_VERSION'] || 'latest',
          'sauce:options': {
            name: test.full_description,
            username: ENV['SAUCE_USERNAME'],
            access_key: ENV['SAUCE_ACCESS_KEY'],
            tunnelIdentifier: ENV['SAUCE_TUNNEL_ID'],
            screenResolution: '1600x1200',
            extendedDebugging: true
          }
        ),
        clear_local_storage: true,
        clear_session_storage: true
      )
    end
  end
  config.after(:each) do |test|
    if is_feature(test)
      # If we're using sauce, we gotta do this to make Sauce Labs
      # know that one e2e test ended and we're about to start the next
      session_id = Capybara.current_session.driver.browser.session_id
      SauceWhisk::Jobs.change_status(session_id, !test.exception)
      Capybara.current_session.quit
    end
  end
end

# This class manages Sauce Connect
class SauceConnectWorker
  SUCCESS_TEXT = 'Sauce Connect is up, you may start your tests.'.freeze
  FAILURE_TEXT = 'Sauce Connect has crashed'.freeze
  def initialize
    puts 'Opening connection to sauce connect'
    @stdin, @stdout, @stderr, @wait_thr = Open3.popen3(ENV, "sc -i #{ENV['SAUCE_TUNNEL_ID']}")
    @is_ready = false
  end

  def wait_until_ready
    until @is_ready
      out = @stdout.gets
      if out.nil?
        err = @stderr.gets
        err = 'No error message provided' if err.empty?
        raise StandardError, "#{FAILURE_TEXT}: #{err}"
      end

      unless out.empty?
        puts out
        @is_ready = true if out.include?(SUCCESS_TEXT)
      end
    end
  end

  # This kills the sauce connect process
  def complete
    @stdin.close
    @stderr.close
    @stdout.close
    Process.kill('KILL', @wait_thr.pid)
  end
end

# This ensures that certain steps are only run for feature tests, eg Capybara tests
def is_feature(test)
  test.metadata[:type].to_s == 'feature'
end
