require 'yaml'
require_relative 'active_record_helpers'

RSpec.configure do |config|
  DATABASE_YAML_FILE = File.join(File.dirname(__FILE__), '../db/database.yml')
  DATABASE_YAML = YAML::load(File.open(DATABASE_YAML_FILE))
  DB = (ENV['DB'] || 'sqlite3').to_sym

  config.before(:suite) do
    require 'active_record'

    ActiveRecord::Base.configurations = DATABASE_YAML
  end

  DATABASE_YAML.keys.each do |db|
    config.before(:all, active_record: true, db.to_sym => true) do
      connect_to_database! db.to_sym
    end
  end

  config.before(:each, active_record: true) do |example|
    require 'database_cleaner'

    already_connected = example.metadata.detect do |meta, value|
      value && DATABASE_YAML.keys.include?(meta.to_s)
    end
    connect_to_database! DB unless already_connected

    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.start
  end

  config.after(:each, active_record: true) do
    DatabaseCleaner.clean
    ActiveRecord::Base.connection.schema_cache.clear!
  end

  config.include ActiveRecordHelpers, active_record: true
end
