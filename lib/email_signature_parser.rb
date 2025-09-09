# frozen_string_literal: true
# modules
# 
require 'facets/string'
require 'mail'
require 'ox'
require 'ruby_postal/parser'
require 'public_suffix'
require 'phone'
require 'yaml'

require_relative "email_signature_parser/parser"
require_relative "email_signature_parser/html_text_parser"

module EmailSignatureParser
  def self.parse_from_file(file_path)
    parser = EmailSignatureParser::Parser.new
    parser.parse_from_file(file_path)
  end
end
