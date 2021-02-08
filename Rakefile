# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require 'rspec/core/rake_task'
require 'rubocop/rake_task'
require_relative 'config/application'

Rails.application.load_tasks
# frozen_string_literal: true

RuboCop::RakeTask.new(:rubocop) do |t|
  t.options = ['--display-cop-names']
end

#
# For use in building a unique Build Name for Sauce Labs
#
ENV['SAUCE_START_TIME'] = "Ruby-RSpec-Selenium: Local-#{Time.now.to_i}"

#
# Ideally run one of these Rake Tasks per build in your CI
#
# Ideally pull these values from a config file instead of hard-coding
#
desc 'Run tests in parallel within suite using Mac Sierra with Chrome'
task :mac_sierra_chrome do
  ENV['PLATFORM_NAME'] = 'macOS 10.12'
  ENV['BROWSER_NAME'] = 'chrome'
  system 'rspec spec'
end

#
# Always set a Default Task
#
task :default do
  Rake::Task[:mac_sierra_chrome].execute
end
