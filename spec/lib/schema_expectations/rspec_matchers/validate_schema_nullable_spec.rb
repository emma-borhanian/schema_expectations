require 'spec_helper'

describe SchemaExpectations::RSpecMatchers::ValidateSchemaNullableMatcher, :active_record do
  shared_examples_for 'Record' do
    def validates(*args)
      Record.instance_eval do
        validates *args
      end
    end

    let(:not_null_attribute) { :not_null }
    let(:nullable_attribute) { :nullable }

    before do
      create_table :records do |t|
        t.string :not_null, null: false
        t.string :nullable
      end

      stub_const('Record', Class.new(ActiveRecord::Base))
    end

    subject(:record) { Record }

    context 'with no validations' do
      it { is_expected.to_not validate_schema_nullable }

      specify '#only' do
        is_expected.to_not validate_schema_nullable.only(:not_null, :nullable)
        is_expected.to_not validate_schema_nullable.only(:not_null)
        is_expected.to validate_schema_nullable.only(:nullable)
      end

      specify '#except' do
        is_expected.to validate_schema_nullable.except(:not_null, :nullable)
        is_expected.to validate_schema_nullable.except(:not_null)
        is_expected.to_not validate_schema_nullable.except(:nullable)
      end
    end

    context 'with not_null present' do
      before { validates not_null_attribute, presence: true }

      it { is_expected.to validate_schema_nullable }

      specify '#only' do
        is_expected.to validate_schema_nullable.only(:not_null, :nullable)
        is_expected.to validate_schema_nullable.only(:not_null)
        is_expected.to validate_schema_nullable.only(:nullable)
      end

      specify '#except' do
        is_expected.to validate_schema_nullable.except(:not_null, :nullable)
        is_expected.to validate_schema_nullable.except(:not_null)
        is_expected.to validate_schema_nullable.except(:nullable)
      end
    end

    context 'with nullable present' do
      before { validates nullable_attribute, presence: true }

      it { is_expected.to_not validate_schema_nullable }

      specify '#only' do
        is_expected.to_not validate_schema_nullable.only(:not_null, :nullable)
        is_expected.to_not validate_schema_nullable.only(:not_null)
        is_expected.to_not validate_schema_nullable.only(:nullable)
      end

      specify '#except' do
        is_expected.to validate_schema_nullable.except(:not_null, :nullable)
        is_expected.to_not validate_schema_nullable.except(:not_null)
        is_expected.to_not validate_schema_nullable.except(:nullable)
      end
    end

    context 'with nullable and not_null present' do
      before do
        validates not_null_attribute, presence: true
        validates nullable_attribute, presence: true
      end

      it { is_expected.to_not validate_schema_nullable }

      specify '#only' do
        is_expected.to_not validate_schema_nullable.only(:not_null, :nullable)
        is_expected.to validate_schema_nullable.only(:not_null)
        is_expected.to_not validate_schema_nullable.only(:nullable)
      end

      specify '#except' do
        is_expected.to validate_schema_nullable.except(:not_null, :nullable)
        is_expected.to_not validate_schema_nullable.except(:not_null)
        is_expected.to validate_schema_nullable.except(:nullable)
      end
    end

    specify '#failure_message_when_negated' do
      validates not_null_attribute, presence: true

      expect do
        is_expected.to_not validate_schema_nullable
      end.to raise_error 'should not match NOT NULL with its presence validation but does'
    end

    specify 'doesnt raise extraneous exceptions from timestamps' do
      create_table :records, force: true do |t|
        t.timestamps null: false
      end
      Record.reset_column_information

      is_expected.to validate_schema_nullable
    end

    context 'ignores validators with' do
      specify 'on: create' do
        validates not_null_attribute, presence: true, on: :create

        expect do
          is_expected.to validate_schema_nullable.only(:not_null)
        end.to raise_error 'not_null is NOT NULL but its presence validator was conditional: {:on=>:create}'
      end

      specify 'if: proc' do
        validates not_null_attribute, presence: true, if: ->{ false }

        expect do
          is_expected.to validate_schema_nullable.only(:not_null)
        end.to raise_error /\Anot_null is NOT NULL but its presence validator was conditional: {:if=>\#<Proc:.*>}\z/
      end

      specify 'unless: proc' do
        validates not_null_attribute, presence: true, unless: ->{ true }

        expect do
          is_expected.to validate_schema_nullable.only(:not_null)
        end.to raise_error /\Anot_null is NOT NULL but its presence validator was conditional: {:unless=>\#<Proc:.*>}\z/
      end

      specify 'allow_nil: true' do
        validates not_null_attribute, presence: true, allow_nil: true

        expect do
          is_expected.to validate_schema_nullable.only(:not_null)
        end.to raise_error 'not_null is NOT NULL but its presence validator was conditional: {:allow_nil=>true}'
      end

      specify 'allow_blank: true' do
        validates not_null_attribute, presence: true, allow_blank: true

        expect do
          is_expected.to validate_schema_nullable.only(:not_null)
        end.to raise_error 'not_null is NOT NULL but its presence validator was conditional: {:allow_blank=>true}'
      end
    end
  end

  context 'called on class' do
    include_examples 'Record' do
      subject(:record) { Record }
    end
  end

  context 'called on instance' do
    include_examples 'Record' do
      subject(:record) { Record.new }
    end
  end

  context 'with belongs_to associations' do
    include_examples 'Record' do
      let(:not_null_attribute) { :not_null_other_record }
      let(:nullable_attribute) { :nullable_other_record }

      before do
        create_table :other_records
        stub_const('OtherRecord', Class.new(ActiveRecord::Base))

        Record.instance_eval do
          belongs_to :not_null_other_record, class_name: 'OtherRecord', foreign_key: :not_null
          belongs_to :nullable_other_record, class_name: 'OtherRecord', foreign_key: :nullable
        end
      end
    end
  end
end
