require 'active_support/core_ext/object/blank'

module SchemaExpectations
  module ActiveRecord
    class ColumnReflector # :nodoc:
      def initialize(model, columns = nil)
        @model = model
        @columns = columns || model.columns
      end

      def column_names
        @columns.map { |column| column.name.to_sym }
      end

      def not_null
        new_with_columns @columns.reject(&:null)
      end

      def for_attributes(*attributes)
        new_with_columns attributes_to_columns(*attributes)
      end

      def without_present_default
        new_with_columns @columns.reject(&method(:present_default_column?))
      end

      private

      def new_with_columns(columns)
        ColumnReflector.new(@model, columns)
      end

      def attributes_to_columns(*attributes)
        column_names = attributes.flat_map(&method(:attribute_to_column_names))
        @columns.select do |column|
          column_names.include? column.name.to_sym
        end
      end

      def attribute_to_column_names(attribute)
        association = @model.reflect_on_association(attribute)

        if association && association.belongs_to? && association.options.key?(:polymorphic)
          [association.foreign_key.to_sym, association.foreign_type.to_sym]
        elsif association && association.belongs_to?
          [association.foreign_key.to_sym]
        else
          [attribute]
        end
      end

      def present_default_column?(column)
        column.default.present? ||
          primary_key?(column) ||
          default_timestamp?(column) ||
          default_function?(column)
      end

      def primary_key?(column)
        column.name.to_s == @model.primary_key.to_s
      end

      def default_timestamp?(column)
        @model.record_timestamps && all_timestamp_attributes.include?(column.name.to_sym)
      end

      def default_function?(column)
        column.respond_to?(:default_function) &&
          column.default_function &&
          function_produces_present_value?(column.default_function)
      end

      def function_produces_present_value?(function)
        query = "SELECT #{function}"
        begin
          result = @model.connection.execute query
          result.first.values.first.present?
        rescue => e
          message = "SchemaExpectations: encountered error running #{query}"
          message << "\n" << e.message
          message << "\n" << e.backtrace.join('\n')
          SchemaExpectations.error_logger.error message
          false
        end
      end

      def all_timestamp_attributes
        @all_timestamp_attributes ||= Record.new.send(:all_timestamp_attributes).map(&:to_sym)
      end
    end
  end
end
