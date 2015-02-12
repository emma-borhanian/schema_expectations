require 'bundler/gem_tasks'
require 'bundler/setup'

begin
  require 'rspec/core/rake_task'

  RSpec::Core::RakeTask.new(:spec)

  task :default => :spec
rescue LoadError
  # no rspec available
end

task :refresh do
  require 'yaml'

  `appraisal install`

  travis_file = File.expand_path('../.travis.yml', __FILE__)
  travis_config = YAML.load(File.read(travis_file))
  travis_config['gemfile'] = Dir.glob("#{File.dirname(__FILE__)}/gemfiles/*.gemfile").
    map { |path| "gemfiles/#{File.basename(path)}" }
  File.open(travis_file, 'w') { |f| f.write YAML.dump(travis_config) }
end
