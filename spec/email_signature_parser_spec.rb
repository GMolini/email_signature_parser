# frozen_string_literal: true
require 'spec_helper'

describe EmailSignatureParser do
  it 'returns hello message' do
    expect(EmailSignatureParser.hello).to eq('Hello from SignatureParser!')
  end
end
