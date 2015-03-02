[![Gem Version](https://badge.fury.io/rb/schema_expectations.svg)](https://rubygems.org/gems/schema_expectations)
[![Build Status](https://travis-ci.org/emma-borhanian/schema_expectations.svg?branch=master)](https://travis-ci.org/emma-borhanian/schema_expectations)
[![Code Climate](https://codeclimate.com/github/emma-borhanian/schema_expectations/badges/gpa.svg)](https://codeclimate.com/github/emma-borhanian/schema_expectations)
[![Test Coverage](https://codeclimate.com/github/emma-borhanian/schema_expectations/badges/coverage.svg)](https://codeclimate.com/github/emma-borhanian/schema_expectations)
[![Dependency Status](https://gemnasium.com/emma-borhanian/schema_expectations.svg)](https://gemnasium.com/emma-borhanian/schema_expectations)

# Schema Expectations

Allows you to test whether your database schema matches the validations in your ActiveRecord models.

# Documentation

You can find documentation at http://www.rubydoc.info/gems/schema_expectations

# Installation

Add `schema_expectations` to your Gemfile:

```ruby
group :test do
  gem 'schema_expectations'
end
```

# Usage with RSpec

## Validating uniqueness constraints

The `validate_schema_uniqueness` matcher tests that an ActiveRecord model
has uniqueness validation on columns with database uniqueness constraints,
and vice versa.

For example, we can assert that the model and database are consistent
on whether `record_type` and `record_id` should be unique:

```ruby
create_table :records do |t|
  t.integer :record_type
  t.integer :record_id
  t.index [:record_type, :record_id], unique: true
end

class Record < ActiveRecord::Base
  validates :record_type, uniqueness: { scope: :record_id }
end

# RSpec
describe Record do
  it { should validate_schema_uniqueness }
end
```

You can restrict the columns tested:

```ruby
# RSpec
describe Record do
  it { should validate_schema_uniqueness.only(:record_id, :record_type) }
  it { should validate_schema_uniqueness.except(:record_id, :record_type) }
end
```

note: if you exclude a column, then every unique scope which includes it will be completely ignored,
regardless of whether that scope includes other non-excluded columns. Only works similarly, in
that it will ignore any scope which contains columns not in the list

## Validating presence constraints

The `validate_schema_nullable` matcher tests that an ActiveRecord model
has unconditional presence validation on columns with `NOT NULL` constraints,
and vice versa.

For example, we can assert that the model and database are consistent
on whether `Record#name` should be present:

```ruby
create_table :records do |t|
  t.string :name, null: false
end

class Record < ActiveRecord::Base
  validates :name, presence: true
end

# RSpec
describe Record do
  it { should validate_schema_nullable }
end
```

You can restrict the columns tested:

```ruby
# RSpec
describe Record do
  it { should validate_schema_nullable.only(:name) }
  it { should validate_schema_nullable.except(:name) }
end
```

The primary key and timestamp columns are automatically skipped.

# License

[MIT License](MIT-LICENSE)
