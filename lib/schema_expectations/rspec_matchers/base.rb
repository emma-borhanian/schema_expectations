require 'rspec/expectations'
require 'schema_expectations/active_record/validation_reflector'
require 'schema_expectations/active_record/column_reflector'

module SchemaExpectations
  module RSpecMatchers
    class Base
      # Specifies a list of columns to restrict matcher
      #
      # @return self
      def only(*args)
        fail 'cannot use only and except' if @except
        @only = Array(args)
        fail 'empty only list' if @only.empty?
        self
      end

      # Specifies a list of columns for matcher to ignore
      #
      # @return self
      def except(*args)
        fail 'cannot use only and except' if @only
        @except = Array(args)
        fail 'empty except list' if @except.empty?
        self
      end

      private

      def setup(model)
        @model = cast_model model
        @validation_reflector = ActiveRecord::ValidationReflector.new(@model)
        @column_reflector = ActiveRecord::ColumnReflector.new(@model)
      end

      def cast_model(model)
        model = model.class if model.is_a?(::ActiveRecord::Base)
        unless model.is_a?(Class) && model.ancestors.include?(::ActiveRecord::Base)
          fail "#{model.inspect} does not inherit from ActiveRecord::Base"
        end
        model
      end
    end
  end
end
