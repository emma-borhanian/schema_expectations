# Schema Expectations Changelog

### git master

- `validate_schema_nullable` skips `created_at` and `updated_at`
- `validate_schema_nullable.only(:id, :created_at, :updated_at)` works
- support activerecord 3.1 to 4.2
- support rspec 3.0 to 3.2
- `validate_schema_nullable` #failure_message_when_negated works
- `validate_schema_nullable` #description works
- `validate_schema_nullable` supports belongs_to association validators
- `validate_schema_nullable` supports polymorphic belongs_to association validators

### 0.0.1 (February 12, 2015)

- `validate_schema_nullable` supports being called on AR instances
- documented `validate_schema_nullable`

### 0.0.0 (February 12, 2015)

- Added `validate_schema_nullable` matcher
