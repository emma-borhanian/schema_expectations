require 'schema_expectations/util'

module SchemaExpectations
  module ActiveRecord
    class ValidationReflector # :nodoc:
      CONDITIONAL_OPTIONS = %i(on if unless)
      ALLOW_NIL_OPTIONS = %i(allow_nil allow_blank)
      ALLOW_EMPTY_OPTIONS = %i(allow_blank)

      def initialize(model, validators = nil)
        @model = model
        @validators = validators || model.validators
      end

      def attributes
        @validators.flat_map(&:attributes).uniq
      end

      def unique_scopes
        validators = validators_with_kind :uniqueness
        validators.flat_map(&method(:validator_scopes))
      end

      def conditions_for_attribute(attribute)
        options_for_attribute attribute, CONDITIONAL_OPTIONS
      end

      def allow_nil_conditions_for_attribute(attribute)
        options_for_attribute attribute, ALLOW_NIL_OPTIONS
      end

      def allow_empty_conditions_for_attribute(attribute)
        options_for_attribute attribute, ALLOW_EMPTY_OPTIONS
      end

      def presence
        new_with_validators validators_with_kind :presence
      end

      def absence
        new_with_validators validators_with_kind :absence
      end

      def unconditional
        new_with_validators validators_without_options CONDITIONAL_OPTIONS
      end

      def disallow_nil
        new_with_validators validators_without_options ALLOW_NIL_OPTIONS
      end

      def disallow_empty
        new_with_validators validators_without_options ALLOW_EMPTY_OPTIONS
      end

      def for_unique_scope(scope)
        scope = scope.sort
        validators = validators_with_kind :uniqueness
        validators.select! do |validator|
          validator_scopes(validator).include? scope
        end
        new_with_validators validators
      end

      private

      def new_with_validators(validators)
        ValidationReflector.new(@model, validators)
      end

      def options_for_attribute(attribute, option_keys)
        validators = validators_for_attribute(attribute)
        validators -= validators_without_options option_keys
        Util.slice_hash(validators.first.options, *option_keys) if validators.first
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

      def validator_scopes(validator)
        scopes = validator.attributes.map do |attribute|
          scope = [attribute] + Array(validator.options[:scope])
          scope.map(&:to_sym).sort
        end
        scopes.sort
      end
    end
  end
end
