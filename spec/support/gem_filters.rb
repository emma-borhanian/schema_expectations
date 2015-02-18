RSpec.configure do |config|
  config.filter_run_excluding active_record_version: ->(version) {
    dependency = Gem::Dependency.new 'activerecord', *Array(version)
    !dependency.match?(Gem.loaded_specs['activerecord'])
  }
end
