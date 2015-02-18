require 'rspec/expectations'
require 'schema_expectations/active_record/validation_reflector'
require 'schema_expectations/active_record/column_reflector'

module SchemaExpectations
  module RSpecMatchers
    # The `validate_schema_nullable` matcher tests that an ActiveRecord model
    # has unconditional presence validation on columns with `NOT NULL` constraints,
    # and vice versa.
    #
    # For example, we can assert that the model and database are consistent
    # on whether `Record#name` should be present:
    #
    #     create_table :records do |t|
    #       t.string :name, null: false
    #     end

    #     class Record < ActiveRecord::Base
    #       validates :name, presence: true
    #     end
    #
    #     # RSpec
    #     describe Record do
    #       it { should validate_schema_nullable }
    #     end
    #
    # You can restrict the columns tested:
    #
    #     # RSpec
    #     describe Record do
    #       it { should validate_schema_nullable.only(:name) }
    #       it { should validate_schema_nullable.except(:name) }
    #     end
    #
    # The primary key and timestamp columns are automatically skipped.
    #
    # @return [ValidateSchemaNullableMatcher]
    def validate_schema_nullable
      ValidateSchemaNullableMatcher.new
    end

    class ValidateSchemaNullableMatcher
      def matches?(model)
        @model = cast_model model
        @validation_reflector = ActiveRecord::ValidationReflector.new(@model)
        @column_reflector = ActiveRecord::ColumnReflector.new(@model)
        @not_null_column_names = filter_column_names(not_null_column_names).sort
        @present_column_names = filter_column_names(present_column_names).sort
        @not_null_column_names == @present_column_names
      end

      def failure_message
        errors = []

        (@present_column_names - @not_null_column_names).each do |column_name|
          errors << "#{column_name} has unconditional presence validation but is missing NOT NULL"
        end

        (@not_null_column_names - @present_column_names).each do |column_name|
          if conditions = validator_conditions_for_column_name(column_name)
            errors << "#{column_name} is NOT NULL but its presence validator was conditional: #{conditions.inspect}"
          else
            errors << "#{column_name} is NOT NULL but has no presence validation"
          end
        end

        errors.join(', ')
      end

      def failure_message_when_negated
        'should not match NOT NULL with its presence validation but does'
      end

      def description
        'validate NOT NULL columns are present'
      end

      # Specifies a list of columns to restrict matcher
      #
      # @return [ValidateSchemaNullableMatcher] self
      def only(*args)
        fail 'cannot use only and except' if @except
        @only = Array(args)
        fail 'empty only list' if @only.empty?
        self
      end

      # Specifies a list of columns for matcher to ignore
      #
      # @return [ValidateSchemaNullableMatcher] self
      def except(*args)
        fail 'cannot use only and except' if @only
        @except = Array(args)
        fail 'empty except list' if @except.empty?
        self
      end

      private

      def cast_model(model)
        model = model.class if model.is_a?(::ActiveRecord::Base)
        unless model.is_a?(Class) && model.ancestors.include?(::ActiveRecord::Base)
          fail "#{model.inspect} does not inherit from ActiveRecord::Base"
        end
        model
      end

      def present_attributes
        @validation_reflector.presence.unconditional.attributes
      end

      def present_column_names
        @column_reflector.for_attributes(*present_attributes).
          without_present_default.column_names
      end

      def column_name_to_attribute(column_name)
        @validation_reflector.attributes.detect do |attribute|
          @column_reflector.for_attributes(attribute).column_names.
            include? column_name
        end
      end

      def not_null_column_names
        @column_reflector.not_null.
          without_present_default.column_names
      end

      def filter_column_names(column_names)
        column_names &= @only if @only
        column_names -= @except if @except
        column_names
      end

      def validator_conditions_for_column_name(column_name)
        @validation_reflector.conditions_for_attribute column_name_to_attribute column_name
      end
    end
  end
end
