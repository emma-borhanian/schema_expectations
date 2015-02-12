begin
  require 'rspec/core'
rescue LoadError
end

if defined?(RSpec)
  require 'schema_expectations/rspec_matchers'

  RSpec.configure do |config|
    config.include SchemaExpectations::RSpecMatchers, type: :model
  end
end
