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
    # The `id` column is automatically skipped.
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
        @not_null_columns = filter_attributes(not_null_columns(model))
        @present_attributes = filter_attributes(present_attributes(model))
        @not_null_columns == @present_attributes
      end

      def failure_message
        @not_null_columns.sort!
        @present_attributes.sort!

        errors = []

        (@present_attributes - @not_null_columns).each do |attribute|
          errors << "#{attribute} has unconditional presence validation but is missing NOT NULL"
        end

        (@not_null_columns - @present_attributes).each do |attribute|
          if condition = validator_condition(@model, attribute)
            errors << "#{attribute} is NOT NULL but its presence validator was conditional: #{condition.inspect}"
          else
            errors << "#{attribute} is NOT NULL but has no presence validation"
          end
        end

        errors.join(', ')
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

      def presence_validators(model)
        presence_validators = model.validators.select do |validator|
          validator.kind == :presence
        end
      end

      def unconditional_presence_validators(model)
        presence_validators(model).select do |validator|
          keep = %i(on if unless).all? do |option_key|
            Array(validator.options[option_key]).empty?
          end

          keep && !validator.options[:allow_nil] && !validator.options[:allow_blank]
        end
      end

      def present_attributes(model)
        present_attributes = unconditional_presence_validators(model).
          flat_map(&:attributes).uniq
        present_attributes &= model.columns.map(&:name).map(&:to_sym)
        present_attributes
      end

      def not_null_columns(model)
        model.columns.select { |column| !column.null }.map(&:name).map(&:to_sym)
      end

      def filter_attributes(attributes)
        attributes &= @only if @only
        attributes -= @except if @except
        attributes -= [:id]
        attributes
      end

      def validator_condition(model, attribute)
        validators = presence_validators(model).select do |validator|
          validator.attributes.include? attribute
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
