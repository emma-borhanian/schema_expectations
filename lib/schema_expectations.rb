require 'schema_expectations/version'
require 'schema_expectations/config'

begin
  require 'rspec/core'
rescue LoadError
end
require 'schema_expectations/rspec' if defined?(RSpec)
