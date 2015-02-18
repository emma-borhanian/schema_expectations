require 'spec_helper'

describe SchemaExpectations::RSpecMatchers::ValidateSchemaNullableMatcher, :active_record do
  shared_examples_for 'Record' do
    def validates(*args)
      Record.instance_eval do
        validates *args
      end
    end

    let(:not_null_columns) { [:not_null] }
    let(:nullable_columns) { [:nullable] }
    let(:columns) { not_null_columns + nullable_columns }

    before do
      create_table :records do |t|
        not_null_columns.each do |column|
          t.string column, null: false
        end

        nullable_columns.each do |column|
          t.string column
        end
      end

      stub_const('Record', Class.new(ActiveRecord::Base))
    end

    subject(:record) { Record }

    context 'with no validations' do
      it { is_expected.to_not validate_schema_nullable }

      specify 'error messages' do
        expect do
          is_expected.to validate_schema_nullable
        end.to raise_error do |error|
          expect(error).to be_a RSpec::Expectations::ExpectationNotMetError
          not_null_columns.sort.zip(error.message.split(', ')) do |column, message|
            expect(message).to eq "#{column} is NOT NULL but has no presence validation"
          end
        end
      end

      specify '#only' do
        is_expected.to_not validate_schema_nullable.only(*columns)
        is_expected.to_not validate_schema_nullable.only(*not_null_columns)
        is_expected.to validate_schema_nullable.only(*nullable_columns)
      end

      specify '#except' do
        is_expected.to validate_schema_nullable.except(*columns)
        is_expected.to validate_schema_nullable.except(*not_null_columns)
        is_expected.to_not validate_schema_nullable.except(*nullable_columns)
      end
    end

    context 'with not_null present' do
      before { validates :not_null, presence: true }

      it { is_expected.to validate_schema_nullable }

      specify '#only' do
        is_expected.to validate_schema_nullable.only(*columns)
        is_expected.to validate_schema_nullable.only(*not_null_columns)
        is_expected.to validate_schema_nullable.only(*nullable_columns)
      end

      specify '#except' do
        is_expected.to validate_schema_nullable.except(*columns)
        is_expected.to validate_schema_nullable.except(*not_null_columns)
        is_expected.to validate_schema_nullable.except(*nullable_columns)
      end
    end

    context 'with nullable present' do
      before { validates :nullable, presence: true }

      it { is_expected.to_not validate_schema_nullable }

      specify 'error messages' do
        expect do
          is_expected.to validate_schema_nullable
        end.to raise_error do |error|
          expect(error).to be_a RSpec::Expectations::ExpectationNotMetError
          errors = error.message.split(', ')

          nullable_columns.sort.zip(errors.take(nullable_columns.size)) do |column, message|
            expect(message).to eq "#{column} has unconditional presence validation but is missing NOT NULL"
          end

          not_null_columns.sort.zip(errors.drop(nullable_columns.size)) do |column, message|
            expect(message).to eq "#{column} is NOT NULL but has no presence validation"
          end
        end
      end

      specify '#only' do
        is_expected.to_not validate_schema_nullable.only(*columns)
        is_expected.to_not validate_schema_nullable.only(*not_null_columns)
        is_expected.to_not validate_schema_nullable.only(*nullable_columns)
      end

      specify '#except' do
        is_expected.to validate_schema_nullable.except(*columns)
        is_expected.to_not validate_schema_nullable.except(*not_null_columns)
        is_expected.to_not validate_schema_nullable.except(*nullable_columns)
      end
    end

    context 'with nullable and not_null present' do
      before do
        validates :not_null, presence: true
        validates :nullable, presence: true
      end

      it { is_expected.to_not validate_schema_nullable }

      specify 'error messages' do
        expect do
          is_expected.to validate_schema_nullable
        end.to raise_error do |error|
          expect(error).to be_a RSpec::Expectations::ExpectationNotMetError
          nullable_columns.sort.zip(error.message.split(', ')) do |column, message|
            expect(message).to eq "#{column} has unconditional presence validation but is missing NOT NULL"
          end
        end
      end

      specify '#only' do
        is_expected.to_not validate_schema_nullable.only(*columns)
        is_expected.to validate_schema_nullable.only(*not_null_columns)
        is_expected.to_not validate_schema_nullable.only(*nullable_columns)
      end

      specify '#except' do
        is_expected.to validate_schema_nullable.except(*columns)
        is_expected.to_not validate_schema_nullable.except(*not_null_columns)
        is_expected.to validate_schema_nullable.except(*nullable_columns)
      end
    end

    specify '#failure_message_when_negated' do
      validates :not_null, presence: true

      expect do
        is_expected.to_not validate_schema_nullable
      end.to raise_error 'should not match NOT NULL with its presence validation but does'
    end

    specify 'when primary_key is not id' do
      create_table :records, force: true, id: false do |t|
        t.integer :pk
      end
      Record.reset_column_information
      Record.instance_eval do
        self.primary_key = 'pk'

        validates :pk, presence: true
      end

      is_expected.to validate_schema_nullable
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
        validates :not_null, presence: true, on: :create

        expect do
          is_expected.to validate_schema_nullable.only(*not_null_columns)
        end.to raise_error do |error|
          expect(error).to be_a RSpec::Expectations::ExpectationNotMetError
          not_null_columns.sort.zip(error.message.split(', ')) do |column, message|
            expect(message).to eq "#{column} is NOT NULL but its presence validator was conditional: {:on=>:create}"
          end
        end
      end

      specify 'if: proc' do
        validates :not_null, presence: true, if: ->{ false }

        expect do
          is_expected.to validate_schema_nullable.only(*not_null_columns)
        end.to raise_error do |error|
          expect(error).to be_a RSpec::Expectations::ExpectationNotMetError
          not_null_columns.sort.zip(error.message.split(', ')) do |column, message|
            expect(message).to match /\A#{column} is NOT NULL but its presence validator was conditional: {:if=>\#<Proc:.*>}\z/
          end
        end
      end

      specify 'unless: proc' do
        validates :not_null, presence: true, unless: ->{ true }

        expect do
          is_expected.to validate_schema_nullable.only(*not_null_columns)
        end.to raise_error do |error|
          expect(error).to be_a RSpec::Expectations::ExpectationNotMetError
          not_null_columns.sort.zip(error.message.split(', ')) do |column, message|
            expect(message).to match /\A#{column} is NOT NULL but its presence validator was conditional: {:unless=>\#<Proc:.*>}\z/
          end
        end
      end

      specify 'allow_nil: true' do
        validates :not_null, presence: true, allow_nil: true

        expect do
          is_expected.to validate_schema_nullable.only(*not_null_columns)
        end.to raise_error do |error|
          expect(error).to be_a RSpec::Expectations::ExpectationNotMetError
          not_null_columns.sort.zip(error.message.split(', ')) do |column, message|
            expect(message).to eq "#{column} is NOT NULL but its presence validator was conditional: {:allow_nil=>true}"
          end
        end
      end

      specify 'allow_blank: true' do
        validates :not_null, presence: true, allow_blank: true

        expect do
          is_expected.to validate_schema_nullable.only(*not_null_columns)
        end.to raise_error do |error|
          expect(error).to be_a RSpec::Expectations::ExpectationNotMetError
          not_null_columns.sort.zip(error.message.split(', ')) do |column, message|
            expect(message).to eq "#{column} is NOT NULL but its presence validator was conditional: {:allow_blank=>true}"
          end
        end
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

  specify 'called on unrecognized object' do
    expect { expect(double('object')).to validate_schema_nullable }.
      to raise_error /#<RSpec::Mocks::Double:0x\h* @name="object"> does not inherit from ActiveRecord::Base/
  end

  context 'with belongs_to associations' do
    include_examples 'Record' do
      let(:not_null_columns) { [:not_null_id] }
      let(:nullable_columns) { [:nullable_id] }

      before do
        create_table :other_records
        stub_const('OtherRecord', Class.new(ActiveRecord::Base))

        Record.instance_eval do
          belongs_to :not_null, class_name: 'OtherRecord', foreign_key: :not_null_id
          belongs_to :nullable, class_name: 'OtherRecord', foreign_key: :nullable_id
        end
      end
    end
  end

  context 'with polymorphic belongs_to associations' do
    include_examples 'Record' do
      let(:not_null_columns) { [:not_null_id, :not_null_type] }
      let(:nullable_columns) { [:nullable_id, :nullable_type] }

      before do
        Record.instance_eval do
          belongs_to :not_null, polymorphic: true, foreign_key: :not_null_id, foreign_type: :not_null_type
          belongs_to :nullable, polymorphic: true, foreign_key: :nullable_id, foreign_type: :nullable_type
        end
      end
    end
  end
end
