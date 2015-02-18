require 'active_support/core_ext/hash/keys'

module ActiveRecordHelpers
  extend Forwardable

  CONNECTION_DELEGATES = %i(create_table execute)

  def connection
    ActiveRecord::Base.connection
  end

  delegate CONNECTION_DELEGATES => :connection

  def setup_postgresql!
    ActiveRecord::Base.connection.execute <<-SQL
      CREATE EXTENSION "uuid-ossp";
    SQL
  end

  # see https://github.com/pat/combustion/blob/master/lib/combustion/database.rb
  def connect_to_database!(db)
    db_config = ActiveRecord::Base.configurations[db.to_s].symbolize_keys

    if ActiveRecord::Base.connected?
      return if ActiveRecord::Base.connection_config == db_config
      ActiveRecord::Base.remove_connection
    end

    case db_config[:adapter]
    when 'sqlite3'
      fail 'only support sqlite3 in-memory' unless db_config[:database] == ':memory:'
    when 'postgresql'
      ActiveRecord::Base.establish_connection(db_config.merge(database: 'postgres'))
      ActiveRecord::Base.connection.drop_database(db_config[:database])
      ActiveRecord::Base.connection.create_database(db_config[:database], db_config)
      ActiveRecord::Base.remove_connection
    when 'mysql2'
      require 'mysql2'
      ActiveRecord::Base.establish_connection(db_config.merge(database: nil))
      ActiveRecord::Base.connection.drop_database(db_config[:database])
      ActiveRecord::Base.connection.create_database(db_config[:database], db_config)
      ActiveRecord::Base.remove_connection
    end

    ActiveRecord::Base.establish_connection(db)
    ActiveRecord::Base.connection # triggers connection to actually happen
    fail "failed to connect to #{db_config.inspect}" unless ActiveRecord::Base.connected?

    setup_postgresql! if db_config[:adapter] == 'postgresql'
  end
end
