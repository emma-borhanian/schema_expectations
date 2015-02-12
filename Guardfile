directories %w(spec)

guard :rspec, cmd: 'bundle exec rspec' do
  watch(%r{^spec/.+_spec\.rb$})
  watch(%r{^spec/support})      { 'spec' }
  watch('spec/spec_helper.rb')  { 'spec' }
end
