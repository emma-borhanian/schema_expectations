require 'spec_helper'

describe SchemaExpectations do
  specify 'Appraisals and .travis.yml are synced' do
    env_bundle_gemfile = ENV['BUNDLE_GEMFILE']
    ENV.delete 'BUNDLE_GEMFILE'

    require 'appraisal'
    require 'yaml'

    travis_file = File.expand_path('../../.travis.yml', __FILE__)
    travis_config = YAML.load(File.read(travis_file))

    Appraisal::File.each do |appraisal|
      error_message = "Appraisal #{appraisal.name} is out of sync. Run `rake refresh`"
      expect(File.file?(appraisal.gemfile_path)).to be_truthy, error_message
      expect(File.read(appraisal.gemfile_path)).to include(appraisal.gemfile.to_s), error_message
      expect(travis_config['gemfile']).to be_a(Array), error_message
      expect(travis_config['gemfile']).to include("gemfiles/#{File.basename(appraisal.gemfile_path)}"), error_message
    end

    ENV['BUNDLE_GEMFILE'] = env_bundle_gemfile
  end

  specify 'binding.pry is not committed' do
    bindings = `git grep binding.pry`.split("\n")
    bindings.reject! do |binding|
      binding.start_with? 'spec/meta_spec.rb:'
    end
    expect(bindings).to be_empty
  end

  specify 'tests connect to postgresql', :active_record, :postgresql do
    expect(ActiveRecord::Base.connection_config[:adapter]).to eq 'postgresql'
  end

  specify 'tests connect to sqlite3', :active_record, :sqlite3 do
    expect(ActiveRecord::Base.connection_config[:adapter]).to eq 'sqlite3'
  end

  specify 'tests connect to mysql2', :active_record, :mysql2 do
    expect(ActiveRecord::Base.connection_config[:adapter]).to eq 'mysql2'
  end
end
