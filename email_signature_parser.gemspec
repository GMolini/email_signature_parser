# frozen_string_literal: true
Gem::Specification.new do |spec|
  spec.name          = 'email_signature_parser'
  spec.version       = '0.1.1'
  spec.authors       = ['Guillermo Molini']
  spec.email         = ['guillermo.molini@gmail.com']

  spec.summary       = 'Email Signature Parser'
  spec.description   = 'A Ruby library for parsing email signatures.'
  spec.homepage      = 'https://github.com/GMolini/email_signature_parser'
  spec.license       = 'MIT'

  spec.files         = Dir['lib/**/*'] + ['README.md']
  spec.require_paths = ['lib']

  spec.add_dependency 'ruby_postal', '~> 1.0'
  spec.add_dependency 'ox', '~> 2.14'
  spec.add_dependency 'mail', '~> 2.5'
  spec.add_dependency 'public_suffix', '~> 5.0'
  spec.add_dependency 'facets', '~> 3.1'

  spec.required_ruby_version = ">= 3.1"

  spec.add_development_dependency('rspec', '~> 3.0')
  spec.add_development_dependency('bundler', '~> 2.0')
  spec.add_development_dependency('rake', '~> 13.0')
  spec.add_development_dependency("simplecov")
  spec.add_development_dependency('pry')
  spec.add_development_dependency('listen', '~> 3.0')
  spec.add_development_dependency('guard')
end