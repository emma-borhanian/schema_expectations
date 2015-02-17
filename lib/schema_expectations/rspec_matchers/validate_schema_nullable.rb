require 'rspec/expectations'

module SchemaExpectations
  module RSpecMatchers
    # The `validate_schema_nullable` matcher test that an ActiveRecord model
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
    # The `id`, `created_at`, and `updated_at` columns are automatically skipped,
    # but may be included using `only`.
    #
    # @return [ValidateSchemaNullableMatcher]
    def validate_schema_nullable
      ValidateSchemaNullableMatcher.new
    end

    class ValidateSchemaNullableMatcher
      def matches?(model)
        model = model.class if model.is_a?(ActiveRecord::Base)
        fail "#{model.inspect} does not inherit from ActiveRecord::Base" unless model.ancestors.include?(ActiveRecord::Base)

        @model = model
        @not_null_column_names = filter_column_names(not_null_column_names)
        @present_column_names = filter_column_names(present_column_names)
        @not_null_column_names == @present_column_names
      end

      def failure_message
        @not_null_column_names.sort!
        @present_column_names.sort!

        errors = []

        (@present_column_names - @not_null_column_names).each do |column_name|
          errors << "#{column_name} has unconditional presence validation but is missing NOT NULL"
        end

        (@not_null_column_names - @present_column_names).each do |column_name|
          if condition = validator_condition(column_name)
            errors << "#{column_name} is NOT NULL but its presence validator was conditional: #{condition.inspect}"
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

      def presence_validators
        presence_validators = @model.validators.select do |validator|
          validator.kind == :presence
        end
      end

      def unconditional_presence_validators
        presence_validators.select do |validator|
          keep = %i(on if unless).all? do |option_key|
            Array(validator.options[option_key]).empty?
          end

          keep && !validator.options[:allow_nil] && !validator.options[:allow_blank]
        end
      end

      def columns
        @model.columns
      end

      def column_names
        columns.map { |column| column.name.to_sym }
      end

      def present_column_names
        present_column_names = unconditional_presence_validators.
          flat_map(&:attributes).uniq.
          map(&method(:attribute_to_column_name))

        present_column_names & column_names
      end

      def attribute_to_column_name(attribute)
        reflection = @model.reflect_on_association(attribute)

        if reflection && reflection.belongs_to?
          reflection.foreign_key
        else
          attribute
        end
      end

      def not_null_column_names
        columns.select { |column| !column.null }.
          map { |column| column.name.to_sym }
      end

      def filter_column_names(column_names)
        column_names &= @only if @only
        column_names -= @except if @except
        column_names -= [:id, :updated_at, :created_at] unless @only
        column_names
      end

      def validator_condition(column_name)
        validators = presence_validators.select do |validator|
          validator.attributes.any? do |attribute|
            column_name == attribute_to_column_name(attribute)
          end
        end

        validators.each do |validator|
          condition = [:on, :if, :unless].detect do |option_key|
            !Array(validator.options[option_key]).empty?
          end

          condition ||= [:allow_nil, :allow_blank].detect do |option_key|
            validator.options[option_key]
          end

          return { condition => validator.options[condition] } if condition
        end

        nil
      end
    end
  end
end
