require "rubygems"
require "rake/testtask"
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new do |t|
  t.rspec_opts = ["-c", "-f progress", "-r ./spec/spec_helper.rb"]
  t.pattern = 'spec/**/*_spec.rb'
end

task :default => :spec

task :yard do
  puts %x{bundle exec yard}
end

task :doc => :yard
