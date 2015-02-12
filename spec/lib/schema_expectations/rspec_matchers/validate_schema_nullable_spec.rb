require 'spec_helper'

describe :validate_schema_nullable do
  specify 'asserts that presence validations match NOT NULL', :active_record do
    create_table :records do |t|
      t.string :not_null, null: false
      t.string :not_null_present, null: false

      t.string :nullable
      t.string :nullable_present
    end

    stub_const('Record', Class.new(ActiveRecord::Base))

    Record.instance_eval do
      validates :not_null_present, presence: true
      validates :nullable_present, presence: true
    end

    expect(Record).to validate_schema_nullable.only(:not_null_present, :nullable)
    expect(Record).to validate_schema_nullable.except(:not_null, :nullable_present)

    expect(Record).to_not validate_schema_nullable
    expect(Record).to_not validate_schema_nullable.only(:not_null)
    expect(Record).to_not validate_schema_nullable.only(:nullable_present)

    expect do
      expect(Record).to validate_schema_nullable.only(:not_null)
    end.to raise_error 'not_null is NOT NULL but has no presence validation'

    expect do
      expect(Record).to validate_schema_nullable.only(:nullable_present)
    end.to raise_error 'nullable_present has unconditional presence validation but is missing NOT NULL'

    Record.instance_eval do
      clear_validators!
      validates :not_null_present, presence: true, on: :create
    end
    expect(Record).to_not validate_schema_nullable.only(:not_null_present)
    expect do
      expect(Record).to validate_schema_nullable.only(:not_null_present)
    end.to raise_error 'not_null_present is NOT NULL but its presence validator was conditional: {:on=>:create}'

    Record.instance_eval do
      clear_validators!
      validates :not_null_present, presence: true, if: ->{ false }
    end
    expect(Record).to_not validate_schema_nullable.only(:not_null_present)
    expect do
      expect(Record).to validate_schema_nullable.only(:not_null_present)
    end.to raise_error /\Anot_null_present is NOT NULL but its presence validator was conditional: {:if=>\#<Proc:.*>}\z/

    Record.instance_eval do
      clear_validators!
      validates :not_null_present, presence: true, unless: ->{ true }
    end
    expect(Record).to_not validate_schema_nullable.only(:not_null_present)
    expect do
      expect(Record).to validate_schema_nullable.only(:not_null_present)
    end.to raise_error /\Anot_null_present is NOT NULL but its presence validator was conditional: {:unless=>\#<Proc:.*>}\z/

    Record.instance_eval do
      clear_validators!
      validates :not_null_present, presence: true, allow_nil: true
    end
    expect(Record).to_not validate_schema_nullable.only(:not_null_present)
    expect do
      expect(Record).to validate_schema_nullable.only(:not_null_present)
    end.to raise_error 'not_null_present is NOT NULL but its presence validator was conditional: {:allow_nil=>true}'

    Record.instance_eval do
      clear_validators!
      validates :not_null_present, presence: true, allow_blank: true
    end
    expect(Record).to_not validate_schema_nullable.only(:not_null_present)
    expect do
      expect(Record).to validate_schema_nullable.only(:not_null_present)
    end.to raise_error 'not_null_present is NOT NULL but its presence validator was conditional: {:allow_blank=>true}'
  end
end
