begin
  require 'rspec/core'
rescue LoadError
end
require 'schema_expectations/rspec' if defined?(RSpec)
