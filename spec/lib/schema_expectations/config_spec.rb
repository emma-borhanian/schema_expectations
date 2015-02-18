require 'spec_helper'
require 'schema_expectations/config'

module SchemaExpectations
  describe Config do
    after do
      SchemaExpectations.configure do |config|
        config.reset!
      end
    end

    specify 'error_logger' do
      expect(SchemaExpectations.error_logger).to be_a Logger

      new_logger = Logger.new(StringIO.new)
      SchemaExpectations.configure do |config|
        config.error_logger = new_logger
      end
      expect(SchemaExpectations.error_logger).to be new_logger
    end
  end
end
