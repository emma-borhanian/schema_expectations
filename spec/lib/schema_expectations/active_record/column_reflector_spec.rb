require 'spec_helper'
require 'schema_expectations/active_record/column_reflector'

module SchemaExpectations
  module ActiveRecord
    describe ColumnReflector, :active_record do
      subject(:column_reflector) { ColumnReflector.new(Record) }

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
