require 'active_record'

module ActiveRecordHelpers
  extend Forwardable

  CONNECTION_DELEGATES = %i(create_table)

  def connection
    ActiveRecord::Base.connection
  end

  delegate CONNECTION_DELEGATES => :connection
end

RSpec.configure do |config|
  config.before(:each, active_record: true) do |example|
    ActiveRecord::Base.establish_connection(
      adapter: 'sqlite3', database: ':memory:')
  end

  config.after(:each, active_record: true) do
    ActiveRecord::Base.remove_connection
  end

  config.include ActiveRecordHelpers, active_record: true
end
