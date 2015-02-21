require 'rspec/core'
require 'schema_expectations/rspec_matchers'

RSpec.configure do |config|
  config.include SchemaExpectations::RSpecMatchers
end
