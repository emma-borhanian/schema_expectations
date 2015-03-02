# Schema Expectations Changelog

### git master

- absence validation absolves requiring uniqueness validation

### 0.4.0 (Febuary 20, 2015)

- include matchers in non-model specs as well
- include model names in failure messages
- fixed a bug in column reflector (test class name was used directly)

### 0.3.0 (Febuary 20, 2015)

- added `validate_schema_uniqueness`

### 0.2.0 (Febuary 18, 2015)

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
- mysql support

### 0.0.1 (February 12, 2015)

- `validate_schema_nullable` supports being called on AR instances
- documented `validate_schema_nullable`

### 0.0.0 (February 12, 2015)

- Added `validate_schema_nullable` matcher
