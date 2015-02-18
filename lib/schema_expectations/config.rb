require 'logger'

module SchemaExpectations
  def self.configure(&block)
    @config.instance_eval(&block)
  end

  def self.error_logger
    @config.error_logger
  end

  class Config
    attr_accessor :error_logger

    def initialize
      reset!
    end

    def reset!
      @error_logger = Logger.new($stderr)
    end
  end

  @config = Config.new
end
