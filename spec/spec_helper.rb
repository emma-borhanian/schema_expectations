require 'codeclimate-test-reporter'
CodeClimate::TestReporter.start

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
