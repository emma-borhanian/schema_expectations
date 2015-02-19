if !ENV['BUNDLE_GEMFILE'] || ENV['BUNDLE_GEMFILE'] =~ /default.gemfile\z/
  if ENV['CI']
    require 'codeclimate-test-reporter'
    CodeClimate::TestReporter.start
  else
    require 'simplecov'
    SimpleCov.start do
      add_filter 'vendor'
    end
  end
end

require 'rspec'
require 'pry'

require 'schema_expectations'

Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each do |file|
  require file
end

RSpec.configure do |config|
  config.raise_errors_for_deprecations!

  config.include SchemaExpectations::RSpecMatchers
end
