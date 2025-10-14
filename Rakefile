require 'rubygems'
require 'bundler/setup'

require 'rake/testtask'
require 'rspec/core/rake_task'

# Load all task files from the tasks directory
Dir.glob('tasks/*.rake').each { |r| load r }

desc "Build a gem file"
task :build do
  system "gem build email_signature_parser.gemspec"
end

task :default => :spec

RSpec::Core::RakeTask.new(:spec) do |t|
  t.ruby_opts = '-w'
  t.rspec_opts = %w(--backtrace --color)
end