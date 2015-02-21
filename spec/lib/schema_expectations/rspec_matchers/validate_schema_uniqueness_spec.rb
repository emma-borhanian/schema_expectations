require 'spec_helper'

describe SchemaExpectations::RSpecMatchers::ValidateSchemaUniquenessMatcher, :active_record do
  shared_examples_for 'Record' do
    def validates(*args)
      Record.instance_eval do
        validates *args
      end
    end

    let(:unique_scope) { [:unique_1_of_1] }

    before do
      create_table :records do |t|
        t.string :no_index
        t.string :index_not_unique

        unique_scope.each do |column_name|
          t.string column_name
        end
      end

      add_index :records, :index_not_unique
      add_index :records, unique_scope, unique: true

      stub_const('Record', Class.new(ActiveRecord::Base))
    end

    subject(:record) { Record }

    context 'with no validations' do
      it { is_expected.to_not validate_schema_uniqueness }

      specify 'error messages' do
        expect { is_expected.to validate_schema_uniqueness }.to(
          raise_error(RSpec::Expectations::ExpectationNotMetError,
            "Record scope #{unique_scope.inspect} has a unique index but no uniqueness validation")
        )
      end

      specify '#only' do
        is_expected.to validate_schema_uniqueness.only(unique_scope.first) if unique_scope.size > 1
        is_expected.to_not validate_schema_uniqueness.only(*unique_scope)
        is_expected.to validate_schema_uniqueness.only(:no_index, :index_not_unique)
        is_expected.to_not validate_schema_uniqueness.only(*unique_scope, :no_index, :index_not_unique)
      end

      specify '#except' do
        is_expected.to validate_schema_uniqueness.except(unique_scope.first)
        is_expected.to validate_schema_uniqueness.except(*unique_scope)
        is_expected.to_not validate_schema_uniqueness.except(:no_index, :index_not_unique)
        is_expected.to validate_schema_uniqueness.except(*unique_scope, :no_index, :index_not_unique)
      end
    end

    context 'validating uniqueness on unique index' do
      before { validates unique_scope.first, uniqueness: { scope: unique_scope.drop(1) } }

      it { is_expected.to validate_schema_uniqueness }

      specify '#only' do
        is_expected.to validate_schema_uniqueness.only(*unique_scope)
        is_expected.to validate_schema_uniqueness.only(:no_index, :index_not_unique)
        is_expected.to validate_schema_uniqueness.only(*unique_scope, :no_index, :index_not_unique)
      end

      specify '#except' do
        is_expected.to validate_schema_uniqueness.except(*unique_scope)
        is_expected.to validate_schema_uniqueness.except(:no_index, :index_not_unique)
      end
    end

    context 'validating uniqueness on not-unique index' do
      before do
        validates unique_scope.first, uniqueness: { scope: unique_scope.drop(1) }
        validates :index_not_unique, uniqueness: true
      end

      it { is_expected.to_not validate_schema_uniqueness }

      specify 'error messages' do
        expect { is_expected.to validate_schema_uniqueness }.to(
          raise_error(RSpec::Expectations::ExpectationNotMetError,
            "Record scope [:index_not_unique] has unconditional uniqueness validation but is missing a unique database index")
        )
      end

      specify '#only' do
        is_expected.to_not validate_schema_uniqueness.only(:index_not_unique)
        is_expected.to validate_schema_uniqueness.only(*unique_scope, :no_index)
      end

      specify '#except' do
        is_expected.to_not validate_schema_uniqueness.except(*unique_scope, :no_index)
        is_expected.to validate_schema_uniqueness.except(:index_not_unique)
      end
    end

    context 'validating uniqueness on column without index' do
      before do
        validates unique_scope.first, uniqueness: { scope: unique_scope.drop(1) }
        validates :no_index, uniqueness: true
      end

      it { is_expected.to_not validate_schema_uniqueness }

      specify 'error messages' do
        expect { is_expected.to validate_schema_uniqueness }.to(
          raise_error(RSpec::Expectations::ExpectationNotMetError,
            "Record scope [:no_index] has unconditional uniqueness validation but is missing a unique database index")
        )
      end

      specify '#only' do
        is_expected.to_not validate_schema_uniqueness.only(:no_index)
        is_expected.to validate_schema_uniqueness.only(*unique_scope, :index_not_unique)
      end

      specify '#except' do
        is_expected.to_not validate_schema_uniqueness.except(*unique_scope, :index_not_unique)
        is_expected.to validate_schema_uniqueness.except(:no_index)
      end
    end

    specify '#failure_message_when_negated' do
      validates unique_scope.first, uniqueness: { scope: unique_scope.drop(1) }

      expect do
        is_expected.to_not validate_schema_uniqueness
      end.to raise_error 'Record should not match unique indexes with its uniqueness validation but does'
    end

    specify 'allows validators with allow_nil: true' do
      validates unique_scope.first, uniqueness: { scope: unique_scope.drop(1) }, allow_nil: true

      is_expected.to validate_schema_uniqueness
    end

    context 'ignores validators with' do
      specify 'on: :create' do
        validates unique_scope.first, uniqueness: { scope: unique_scope.drop(1) }, on: :create

        expect { is_expected.to validate_schema_uniqueness }.to(
          raise_error(RSpec::Expectations::ExpectationNotMetError,
            "Record scope #{unique_scope.inspect} has a unique index but its uniqueness validator was conditional: {:on=>:create}")
        )
      end

      specify 'if: proc' do
        validates unique_scope.first, uniqueness: { scope: unique_scope.drop(1) }, if: ->{ false }

        expect { is_expected.to validate_schema_uniqueness }.to(
          raise_error(RSpec::Expectations::ExpectationNotMetError,
            /\ARecord scope #{Regexp.escape(unique_scope.inspect)} has a unique index but its uniqueness validator was conditional: {:if=>\#<Proc:.*>}\z/)
        )
      end

      specify 'unless: proc' do
        validates unique_scope.first, uniqueness: { scope: unique_scope.drop(1) }, unless: ->{ false }

        expect { is_expected.to validate_schema_uniqueness }.to(
          raise_error(RSpec::Expectations::ExpectationNotMetError,
            /\ARecord scope #{Regexp.escape(unique_scope.inspect)} has a unique index but its uniqueness validator was conditional: {:unless=>\#<Proc:.*>}\z/)
        )
      end

      specify 'allow_blank: true' do
        validates unique_scope.first, uniqueness: { scope: unique_scope.drop(1) }, allow_blank: true

        expect { is_expected.to validate_schema_uniqueness }.to(
          raise_error(RSpec::Expectations::ExpectationNotMetError,
            "Record scope #{unique_scope.inspect} has a unique index but its uniqueness validator was conditional: {:allow_blank=>true}")
        )
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

  context 'with two columns' do
    include_examples 'Record' do
      let(:unique_scope) { [:unique_1_of_2, :unique_2_of_2] }
    end
  end
  specify 'called on unrecognized object' do
    expect { expect(double('object')).to validate_schema_uniqueness }.
      to raise_error /#<RSpec::Mocks::Double:0x\h* @name="object"> does not inherit from ActiveRecord::Base/
  end
end
