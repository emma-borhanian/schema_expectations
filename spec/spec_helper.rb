require 'rspec'

Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each do |file|
  require file
end

RSpec.configure do |config|
  config.raise_errors_for_deprecations!
end
