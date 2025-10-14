# encoding: utf-8
# frozen_string_literal: true

require 'simplecov'

SimpleCov.start do
  add_filter 'spec/'
  
end

require 'rspec'
require 'email_signature_parser'

unless defined?(SPEC_ROOT)
  SPEC_ROOT = __dir__
end

RSpec.configure do |config|
  config.mock_with :rspec


  config.filter_run_when_matching :focus

end

def fixture_path(*path)
  File.join SPEC_ROOT, 'fixtures', path
end

def read_raw_fixture(*path)
  File.open fixture_path(*path), 'rb', &:read
end