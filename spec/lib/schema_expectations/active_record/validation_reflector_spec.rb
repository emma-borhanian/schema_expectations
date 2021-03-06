require 'spec_helper'
require 'schema_expectations/active_record/validation_reflector'

module SchemaExpectations
  module ActiveRecord
    describe ValidationReflector, :active_record do
      before do
        create_table :records

        stub_const('Record', Class.new(::ActiveRecord::Base))
      end

      subject(:validation_reflector) { ValidationReflector.new(Record) }

      specify 'allows filtering attributes' do
        Record.instance_eval do
          validates :present, presence: true
          validates :not_present, length: { minimum: 1 }
          validates :conditional_1, presence: true, on: :create
          validates :conditional_2, presence: true, if: ->{ false }
          validates :conditional_3, presence: true, unless: ->{ false }
          validates :conditional_4, presence: true, allow_nil: true
          validates :conditional_5, presence: true, allow_blank: true
        end

        expect(validation_reflector.attributes).to eq %i(
          present not_present conditional_1 conditional_2
          conditional_3 conditional_4 conditional_5)

        expect(validation_reflector.unconditional.attributes).to eq %i(present not_present conditional_4 conditional_5)

        expect(validation_reflector.disallow_nil.attributes).to eq %i(present not_present conditional_1 conditional_2 conditional_3)

        expect(validation_reflector.disallow_empty.attributes).to eq %i(present not_present conditional_1 conditional_2 conditional_3 conditional_4)

        expect(validation_reflector.presence.attributes).to eq %i(
          present conditional_1 conditional_2
          conditional_3 conditional_4 conditional_5)

        expect(validation_reflector.unconditional.presence.disallow_nil.attributes).to eq %i(present)
        expect(validation_reflector.presence.unconditional.disallow_nil.attributes).to eq %i(present)
      end

      specify '#absence', active_record_version: '>= 4.0' do
        Record.instance_eval do
          validates :absent, absence: true
          validates :not_absent, length: { minimum: 1 }
        end

        expect(validation_reflector.attributes).to eq %i(absent not_absent)
        expect(validation_reflector.absence.attributes).to eq %i(absent)
      end

      specify '#for_unique_scope' do
        Record.instance_eval do
          validates :a, uniqueness: true
          validates :a, :d, uniqueness: { scope: %i(b) }
          validates :c, uniqueness: { scope: %i(a b) }
        end

        expect(validation_reflector.for_unique_scope(%i(missing)).attributes).to be_empty
        expect(validation_reflector.for_unique_scope(%i(a)).attributes).to eq %i(a)
        expect(validation_reflector.for_unique_scope(%i(a b)).attributes).to eq %i(a d)
        expect(validation_reflector.for_unique_scope(%i(b a)).attributes).to eq %i(a d)
        expect(validation_reflector.for_unique_scope(%i(b d)).attributes).to eq %i(a d)
        expect(validation_reflector.for_unique_scope(%i(a b c)).attributes).to eq %i(c)
        expect(validation_reflector.for_unique_scope(%i(c b a)).attributes).to eq %i(c)
      end

      specify '#unique_scopes' do
        Record.instance_eval do
          validates :a, uniqueness: true
          validates :b, uniqueness: { scope: %i(a) }
          validates :c, uniqueness: { scope: %i(a b) }
          validates :d, uniqueness: { scope: %i(b) }
        end

        expect(validation_reflector.unique_scopes).to eq [
          %i(a),
          %i(a b),
          %i(a b c),
          %i(b d)
        ]
      end

      context 'conditions' do
        before do
          Record.instance_eval do
            validates :present, presence: true
            validates :not_present, length: { minimum: 1 }
            validates :conditional_1, presence: true, on: :create
            validates :conditional_2, presence: true, if: ->{ false }
            validates :conditional_3, presence: true, unless: ->{ false }
            validates :conditional_4, presence: true, allow_nil: true
            validates :conditional_5, presence: true, allow_blank: true
          end
        end

        specify '#conditions_for_attribute' do
          expect(validation_reflector.conditions_for_attribute(:missing)).to be_nil
          expect(validation_reflector.conditions_for_attribute(:present)).to be_nil
          expect(validation_reflector.conditions_for_attribute(:not_present)).to be_nil
          expect(validation_reflector.conditions_for_attribute(:conditional_1)).to eq(on: :create)
          expect(validation_reflector.conditions_for_attribute(:conditional_2).keys).to eq [:if]
          expect(validation_reflector.conditions_for_attribute(:conditional_3).keys).to eq [:unless]
          expect(validation_reflector.conditions_for_attribute(:conditional_4)).to be_nil
          expect(validation_reflector.conditions_for_attribute(:conditional_5)).to be_nil
        end

        specify '#allow_nil_conditions_for_attribute' do
          expect(validation_reflector.allow_nil_conditions_for_attribute(:missing)).to be_nil
          expect(validation_reflector.allow_nil_conditions_for_attribute(:present)).to be_nil
          expect(validation_reflector.allow_nil_conditions_for_attribute(:not_present)).to be_nil
          expect(validation_reflector.allow_nil_conditions_for_attribute(:conditional_1)).to be_nil
          expect(validation_reflector.allow_nil_conditions_for_attribute(:conditional_2)).to be_nil
          expect(validation_reflector.allow_nil_conditions_for_attribute(:conditional_3)).to be_nil
          expect(validation_reflector.allow_nil_conditions_for_attribute(:conditional_4)).to eq(allow_nil: true)
          expect(validation_reflector.allow_nil_conditions_for_attribute(:conditional_5)).to eq(allow_blank: true)
        end

        specify '#allow_empty_conditions_for_column_name' do
          expect(validation_reflector.allow_empty_conditions_for_attribute(:missing)).to be_nil
          expect(validation_reflector.allow_empty_conditions_for_attribute(:present)).to be_nil
          expect(validation_reflector.allow_empty_conditions_for_attribute(:not_present)).to be_nil
          expect(validation_reflector.allow_empty_conditions_for_attribute(:conditional_1)).to be_nil
          expect(validation_reflector.allow_empty_conditions_for_attribute(:conditional_2)).to be_nil
          expect(validation_reflector.allow_empty_conditions_for_attribute(:conditional_3)).to be_nil
          expect(validation_reflector.allow_empty_conditions_for_attribute(:conditional_4)).to be_nil
          expect(validation_reflector.allow_empty_conditions_for_attribute(:conditional_5)).to eq(allow_blank: true)
        end
      end
    end
  end
end
