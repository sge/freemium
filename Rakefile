#!/usr/bin/env rake
require "bundler/gem_tasks"

require 'rspec/core'
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = FileList['spec/**/*_spec.rb']
end

RSpec::Core::RakeTask.new(:rcov) do |spec|
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
end

task :default => :spec

require 'rdoc/task'
Rake::RDocTask.new do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = Freemium::VERSION
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

namespace :db do
  desc "Migrate the database"
  task(:migrate) do
    require 'active_record'
    ActiveRecord::Base.establish_connection({
      adapter: 'mysql2',
      host: '127.0.0.1',
      database: 'freemium_test',
      username: 'root',
      password: nil
    })
    puts File.expand_path("../migrations",__FILE__)
    ActiveRecord::Base.logger = Logger.new(STDOUT)
    ActiveRecord::Migration.verbose = true
    ActiveRecord::Migrator.migrate(File.expand_path("../migrations",__FILE__))
  end
end