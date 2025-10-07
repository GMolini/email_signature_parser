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
require 'cgi'

require_relative "email_signature_parser/parser"
require_relative "email_signature_parser/html_text_parser"
require_relative "email_signature_parser/utils"

module EmailSignatureParser
  def self.from_file(file_path)
    parser = EmailSignatureParser::Parser.new
    parser.parse_from_file(file_path)
  end

  def self.from_html(from, email_body)
    parser = EmailSignatureParser::Parser.new
    parser.parse_from_html(from, email_body)
  end

  def self.from_text(from, email_body)
    parser = EmailSignatureParser::Parser.new
    parser.parse_from_text(from, email_body)
  end

end
