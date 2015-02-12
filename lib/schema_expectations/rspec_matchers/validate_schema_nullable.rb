require 'rspec/expectations'

RSpec::Matchers.define :validate_schema_nullable do
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

  match do |model|
    filter_attributes(not_null_columns(model)) == filter_attributes(present_attributes(model))
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

  failure_message do |model|
    not_null_columns = filter_attributes(not_null_columns(model)).sort
    present_attributes = filter_attributes(present_attributes(model)).sort

    errors = []

    (present_attributes - not_null_columns).each do |attribute|
      errors << "#{attribute} has unconditional presence validation but is missing NOT NULL"
    end

    (not_null_columns - present_attributes).each do |attribute|
      if condition = validator_condition(model, attribute)
        errors << "#{attribute} is NOT NULL but its presence validator was conditional: #{condition.inspect}"
      else
        errors << "#{attribute} is NOT NULL but has no presence validation"
      end
    end

    errors.join(', ')
  end

  chain :only do |*only|
    fail 'cannot use only and except' if @except
    @only = Array(only)
    fail 'empty only list' if @only.empty?
  end

  chain :except do |*except|
    fail 'cannot use only and except' if @only
    @except = Array(except)
    fail 'empty except list' if @except.empty?
  end
end
