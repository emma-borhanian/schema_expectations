require 'spec_helper'
require 'schema_expectations/active_record/column_reflector'

module SchemaExpectations
  module ActiveRecord
    describe ColumnReflector, :active_record do
      subject(:column_reflector) { ColumnReflector.new(Record) }

      context '#without_present_default' do
        specify 'filters default values' do
          create_table :records do |t|
            t.integer :integer_default, default: 0
            t.string :string_default, default: 'test'
            t.string :empty_default, default: ''
            t.string :null_default, default: nil
            t.string :no_default

            t.timestamps null: false
          end
          stub_const('Record', Class.new(::ActiveRecord::Base))

          expect(column_reflector.column_names).
            to eq %i(id integer_default string_default empty_default null_default no_default created_at updated_at)

          expect(column_reflector.without_present_default.column_names).
            to eq %i(empty_default null_default no_default)
        end

        context 'default functions', :postgresql, active_record_version: '>= 4.0' do
          specify 'are filtered' do
            create_table :records do |t|
              t.uuid :uuid_default, default: 'uuid_generate_v4()'
              t.string :no_default
            end
            execute <<-SQL
              -- not possible via create_table syntax right now
              ALTER TABLE records
                ADD COLUMN function_default float DEFAULT random();
            SQL
            stub_const('Record', Class.new(::ActiveRecord::Base))

            expect(Record.columns_hash['function_default'].default).to be_nil
            expect(Record.columns_hash['uuid_default'].default).to be_nil
            expect(Record.columns_hash['function_default'].default_function).to_not be_nil
            expect(Record.columns_hash['uuid_default'].default_function).to_not be_nil

            expect(column_reflector.column_names).
              to eq %i(id uuid_default no_default function_default)

            expect(column_reflector.without_present_default.column_names).
              to eq %i(no_default)
          end

          specify 'logs if it encounters an error trying to run default function' do
            create_table :records
            execute <<-SQL
              CREATE FUNCTION raise_error() RETURNS varchar
                AS $BODY$
                  BEGIN
                    RAISE 'test exception';
                  END;
                $BODY$
                LANGUAGE plpgsql;

              -- not possible via create_table syntax right now
              ALTER TABLE records
                ADD COLUMN function_default varchar DEFAULT raise_error();
            SQL
            stub_const('Record', Class.new(::ActiveRecord::Base))

            expect(Record.columns_hash['function_default'].default).to be_nil
            expect(Record.columns_hash['function_default'].default_function).to_not be_nil

            expect(column_reflector.column_names).
              to eq %i(id function_default)

            expect(SchemaExpectations.error_logger).to receive(:error).once do |message|
              expect(message).to include 'SchemaExpectations: encountered error running SELECT raise_error()'
              expect(message).to include 'PG::RaiseException: ERROR:  test exception'
              expect(message).to include ': SELECT raise_error()'
            end
            expect(column_reflector.without_present_default.column_names).
              to eq %i(function_default)
          end
        end
      end

      specify '#not_null' do
        create_table :records do |t|
          t.string :not_null, null: false
          t.string :nullable
        end
        stub_const('Record', Class.new(::ActiveRecord::Base))

        expect(column_reflector.column_names).to eq %i(id not_null nullable)
        expect(column_reflector.not_null.column_names).to eq %i(id not_null)
      end

      context '#for_attributes' do
        before do
          create_table :records do |t|
            t.string :record_id
            t.string :record_type
            t.string :other
          end

          stub_const('Record', Class.new(::ActiveRecord::Base))
        end

        specify 'without associations' do
          expect(column_reflector.column_names).to eq %i(id record_id record_type other)
          expect(column_reflector.for_attributes(:missing).column_names).to be_empty
          expect(column_reflector.for_attributes(:record).column_names).to be_empty
          expect(column_reflector.for_attributes(:record_id).column_names).to eq %i(record_id)
          expect(column_reflector.for_attributes(:record_type).column_names).to eq %i(record_type)
          expect(column_reflector.for_attributes(:other).column_names).to eq %i(other)
          expect(column_reflector.for_attributes(*%i(record missing other)).column_names).to eq %i(other)
        end

        specify 'belongs_to polymorphic' do
          Record.instance_eval do
            belongs_to :record, polymorphic: true
          end

          expect(column_reflector.column_names).to eq %i(id record_id record_type other)
          expect(column_reflector.for_attributes(:missing).column_names).to be_empty
          expect(column_reflector.for_attributes(:record).column_names).to eq %i(record_id record_type)
          expect(column_reflector.for_attributes(:record_id).column_names).to eq %i(record_id)
          expect(column_reflector.for_attributes(:record_type).column_names).to eq %i(record_type)
          expect(column_reflector.for_attributes(:other).column_names).to eq %i(other)
          expect(column_reflector.for_attributes(*%i(record missing other)).column_names).to eq %i(record_id record_type other)
        end

        specify 'belongs_to' do
          Record.instance_eval do
            belongs_to :record
          end

          expect(column_reflector.column_names).to eq %i(id record_id record_type other)
          expect(column_reflector.for_attributes(:missing).column_names).to be_empty
          expect(column_reflector.for_attributes(:record).column_names).to eq %i(record_id)
          expect(column_reflector.for_attributes(:record_id).column_names).to eq %i(record_id)
          expect(column_reflector.for_attributes(:record_type).column_names).to eq %i(record_type)
          expect(column_reflector.for_attributes(:other).column_names).to eq %i(other)
          expect(column_reflector.for_attributes(*%i(record missing other)).column_names).to eq %i(record_id other)
        end
      end
    end
  end
end
