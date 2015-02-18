module SchemaExpectations
  module Util # :nodoc:
    def self.slice_hash(hash, *keys)
      keys.each_with_object(hash.class.new) do |key, memo|
        memo[key] = hash[key] if hash.has_key?(key)
      end
    end
  end
end
