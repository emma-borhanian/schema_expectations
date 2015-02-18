require 'spec_helper'
require 'schema_expectations/util'

module SchemaExpectations
  describe SchemaExpectations::Util do
    specify '.slice_hash' do
      expect(Util.slice_hash({}, :key)).to eq({})
      expect(Util.slice_hash({ key: :value }, :key)).to eq(key: :value)
      expect(Util.slice_hash({ other: :value }, :key)).to eq({})
      expect(Util.slice_hash({
        key_1: :value_1,
        key_2: :value_2,
        other: :value_3 }, :key_1, :key_2)).to eq(key_1: :value_1, key_2: :value_2)
    end
  end
end
