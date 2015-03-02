require 'rspec/expectations'
require 'schema_expectations/rspec_matchers/base'

module SchemaExpectations
  module RSpecMatchers
    # The `validate_schema_uniqueness` matcher tests that an ActiveRecord model
    # has uniqueness validation on columns with database uniqueness constraints,
    # and vice versa.
    #
    # For example, we can assert that the model and database are consistent
    # on whether `record_type` and `record_id` should be unique:
    #
    #     create_table :records do |t|
    #       t.integer :record_type
    #       t.integer :record_id
    #       t.index [:record_type, :record_id], unique: true
    #     end
    #
    #     class Record < ActiveRecord::Base
    #       validates :record_type, uniqueness: { scope: :record_id }
    #     end
    #
    #     # RSpec
    #     describe Record do
    #       it { should validate_schema_uniqueness }
    #     end
    #
    # You can restrict the columns tested:
    #
    #     # RSpec
    #     describe Record do
    #       it { should validate_schema_uniqueness.only(:record_id, :record_type) }
    #       it { should validate_schema_uniqueness.except(:record_id, :record_type) }
    #     end
    #
    # note: if you exclude a column, then every unique scope which includes it will be completely ignored,
    # regardless of whether that scope includes other non-excluded columns. Only works similarly, in
    # that it will ignore any scope which contains columns not in the list
    #
    # Absence validation on any attribute in a scope absolves requiring uniqueness validation.
    #
    # @return [ValidateSchemaUniquenessMatcher]
    def validate_schema_uniqueness
      ValidateSchemaUniquenessMatcher.new
    end

    class ValidateSchemaUniquenessMatcher < Base
      def matches?(model)
        setup(model)
        (@validator_unique_scopes - @schema_unique_scopes).empty? &&
          (@schema_unique_scopes - @validator_unique_scopes - absent_scopes).empty?
      end

      def failure_message
        errors = []

        (@validator_unique_scopes - @schema_unique_scopes).each do |scope|
          errors << "#{@model.name} scope #{scope.inspect} has unconditional uniqueness validation but is missing a unique database index"
        end

        (@schema_unique_scopes - @validator_unique_scopes - absent_scopes).each do |scope|
          conditions = validator_conditions_for_scope(scope) ||
            validator_allow_empty_conditions_for_scope(scope)
          if conditions
            errors << "#{@model.name} scope #{scope.inspect} has a unique index but its uniqueness validator was conditional: #{conditions.inspect}"
          else
            errors << "#{@model.name} scope #{scope.inspect} has a unique index but no uniqueness validation"
          end
        end

        errors.join(', ')
      end

      def failure_message_when_negated
        "#{@model.name} should not match unique indexes with its uniqueness validation but does"
      end

      def description
        'validate unique indexes have uniqueness validation'
      end

      private

      def setup(model)
        super
        @validator_unique_scopes = deep_sort(filter_scopes(validator_unique_scopes))
        @schema_unique_scopes = deep_sort(filter_scopes(schema_unique_scopes))
      end

      def validator_unique_scopes
        @validation_reflector.unconditional.disallow_empty.unique_scopes
      end

      def schema_unique_scopes
        @column_reflector.unique_scopes
      end

      def filter_scopes(scopes)
        if @only
          scopes.select { |scope| (scope - @only).empty? }
        elsif @except
          scopes.select { |scope| (scope & @except).empty? }
        else
          scopes
        end
      end

      def deep_sort(scopes)
        scopes.map(&:sort).sort
      end

      def validator_conditions_for_scope(scope)
        validator_conditions(scope) do |reflector, attribute|
          reflector.conditions_for_attribute attribute
        end
      end

      def validator_allow_empty_conditions_for_scope(scope)
        validator_conditions(scope) do |reflector, attribute|
          reflector.allow_empty_conditions_for_attribute attribute
        end
      end

      def validator_conditions(scope)
        reflector = @validation_reflector.for_unique_scope(scope)
        conditions = reflector.attributes.map do |attribute|
          yield reflector, attribute
        end
        conditions.compact.first
      end

      def absent_scopes
        scopes = @validator_unique_scopes + @schema_unique_scopes
        absent_attributes = @validation_reflector.
          absence.unconditional.disallow_empty.attributes
        absent_columns = @column_reflector.for_attributes(*absent_attributes).column_names

        scopes.reject do |scope|
          (scope & absent_columns).empty?
        end
      end
    end
  end
end
