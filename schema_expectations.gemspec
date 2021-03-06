require File.expand_path('../lib/schema_expectations/version', __FILE__)

Gem::Specification.new do |gem|
  gem.platform      = Gem::Platform::RUBY
  gem.name          = 'schema_expectations'
  gem.version       = SchemaExpectations::VERSION
  gem.summary       = 'Database Schema Expectations'
  gem.description   = %q(
    Allows you to test whether your database schema
    matches the validations in your ActiveRecord models.'
  )
  gem.license       = 'MIT'

  gem.authors       = ['Emma Borhanian']
  gem.email         = 'emma.borhanian+schema_expectations@gmail.com'
  gem.homepage      = 'https://github.com/emma-borhanian/schema_expectations'

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^spec/})
  gem.require_paths = %w(lib)

  gem.required_ruby_version = '>= 2.0.0'

  gem.add_dependency 'activerecord', '>= 3.1', '< 4.3'
  gem.add_dependency 'activesupport', '>= 3.1', '< 4.3'

  # optional dependency
  gem.add_development_dependency 'rspec', '>= 3.0', '< 3.3'

  gem.add_development_dependency 'pry'
  gem.add_development_dependency 'rake', '~> 10.4'
  gem.add_development_dependency 'yard', '~> 0.8.7'

  # tests
  gem.add_development_dependency 'wwtd'
  gem.add_development_dependency 'appraisal', '~> 1.0'
  gem.add_development_dependency 'codeclimate-test-reporter', '~> 0.4', '>= 0.4.6'
  gem.add_development_dependency 'simplecov'
  gem.add_development_dependency 'guard-rspec', '~> 4.5'
  gem.add_development_dependency 'sqlite3', '~> 1.3'
  gem.add_development_dependency 'pg', '~> 0.18'
  gem.add_development_dependency 'mysql2', '~> 0.3.18'
  gem.add_development_dependency 'database_cleaner', '~> 1.4'
end
