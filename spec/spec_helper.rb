DEFAULT_GEMFILES = [
  File.expand_path('../../Gemfile', __FILE__),
  File.expand_path('../../gemfiles/default.gemfile', __FILE__)
]
if ENV['CI']
  if !ENV['BUNDLE_GEMFILE'] ||
    DEFAULT_GEMFILES.include?(File.expand_path(ENV['BUNDLE_GEMFILE']))
    require 'codeclimate-test-reporter'
    CodeClimate::TestReporter.start
  end
else
  require 'simplecov'
  SimpleCov.start do
    add_filter 'vendor'
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
