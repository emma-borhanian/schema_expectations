require 'schema_expectations/util'

module SchemaExpectations
  module ActiveRecord
    class ValidationReflector # :nodoc:
      CONDITIONAL_OPTIONS = %i(on if unless allow_nil allow_blank)

      def initialize(model, validators = nil)
        @model = model
        @validators = validators || model.validators
      end

      def attributes
        @validators.flat_map(&:attributes).uniq
      end

      def conditions_for_attribute(attribute)
        validators = validators_for_attribute(attribute)
        validators -= validators_without_options CONDITIONAL_OPTIONS
        Util.slice_hash(validators.first.options, *CONDITIONAL_OPTIONS) if validators.first
      end

      def presence
        new_with_validators validators_with_kind :presence
      end

      def unconditional
        new_with_validators validators_without_options CONDITIONAL_OPTIONS
      end

      private

      def new_with_validators(validators)
        ValidationReflector.new(@model, validators)
      end

      def validators_with_kind(kind)
        @validators.select do |validator|
          validator.kind == kind
        end
      end

      def validators_without_options(options)
        @validators.select do |validator|
          options.all? do |option_key|
            !validator.options[option_key] ||
              Array(validator.options[option_key]).empty?
          end
        end
      end

      def validators_for_attribute(attribute)
        @validators.select do |validator|
          validator.attributes.include? attribute
        end
      end
    end
  end
end
