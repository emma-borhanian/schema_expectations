# Schema Expectations Changelog

### git master

- support activerecord 3.1 to 4.2
- support rspec 3.0 to 3.2
- `validate_schema_nullable` #failure_message_when_negated works
- `validate_schema_nullable` #description works
- `validate_schema_nullable` supports belongs_to association validators
- `validate_schema_nullable` supports polymorphic belongs_to association validators
- `validate_schema_nullable` skips primary key and timestamps
- `validate_schema_nullable` is aware of columns with default values
- `validate_schema_nullable` is aware of columns with default functions
- postgres support

### 0.0.1 (February 12, 2015)

- `validate_schema_nullable` supports being called on AR instances
- documented `validate_schema_nullable`

### 0.0.0 (February 12, 2015)

- Added `validate_schema_nullable` matcher
