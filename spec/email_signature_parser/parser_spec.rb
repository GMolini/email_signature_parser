# encoding: UTF-8
require 'spec_helper'

RSpec.describe EmailSignatureParser::Parser do
  let(:parser) { described_class.new }
  
  describe '#initialize' do
    it 'creates a new parser instance' do
      expect(parser).to be_an_instance_of(EmailSignatureParser::Parser)
    end
    
    it 'initializes signature_sentences as empty array' do
      expect(parser.instance_variable_get(:@signature_sentences)).to eq([])
    end
  end

  describe '#meeting_email?' do
    context 'when email contains meeting links' do
      it 'returns true for zoom links' do
        email_body = "Join our meeting: https://zoom.us/j/123456789"
        expect(parser.meeting_email?(email_body)).to be true
      end
      
      it 'returns true for teams links' do
        email_body = "Meeting link: https://teams.microsoft.com/l/meetup-join/123"
        expect(parser.meeting_email?(email_body)).to be true
      end
      
      it 'returns true for google meet links' do
        email_body = "Join here: https://meet.google.com/abc-defg-hij"
        expect(parser.meeting_email?(email_body)).to be true
      end
      
      it 'returns true for webex links' do
        email_body = "WebEx meeting: https://webex.com/meet/123"
        expect(parser.meeting_email?(email_body)).to be true
      end
    end
    
    context 'when email does not contain meeting links' do
      it 'returns false for regular email' do
        email_body = "Hello, this is a regular email with no meeting links."
        expect(parser.meeting_email?(email_body)).to be false
      end
      
      it 'returns false for empty email' do
        expect(parser.meeting_email?("")).to be false
      end
      
      it 'returns false for nil' do
        expect(parser.meeting_email?(nil)).to be false
      end
    end
  end

  describe '#extract_name_and_email' do
    context 'with valid from headers' do
      it 'extracts name and email from standard format' do
        from = "John Doe <john.doe@example.com>"
        name, email = parser.extract_name_and_email(from)
        expect(name).to eq("John Doe")
        expect(email).to eq("john.doe@example.com")
      end
      
      it 'extracts name and email with quotes' do
        from = '"Jane Smith" <jane.smith@company.com>'
        name, email = parser.extract_name_and_email(from)
        expect(name).to eq("Jane Smith")
        expect(email).to eq("jane.smith@company.com")
      end
      
      it 'handles email only format' do
        from = "user@domain.com"
        name, email = parser.extract_name_and_email(from)
        expect(name).to eq("")
        expect(email).to eq("user@domain.com")
      end
      
      it 'handles name with special characters' do
        from = "José María <jose.maria@empresa.es>"
        name, email = parser.extract_name_and_email(from)
        expect(name).to eq("José María")
        expect(email).to eq("jose.maria@empresa.es")
      end
    end
    
    context 'with empty parameters' do
      it 'Returns empty string if from is empty' do
        name, email = parser.extract_name_and_email("")
        expect(name).to eq("")
        expect(email).to eq("")
      end
      
      it 'returns empty string if from is nil' do
        name, email = parser.extract_name_and_email(nil)
        expect(name).to eq("")
        expect(email).to eq("")
      end

    end
  end

  describe '#split_in_threads' do
    it 'splits email by thread markers' do
      email_text = <<~EMAIL
        Original message here.
        
        -----Original Message-----
        From: sender@example.com
        To: recipient@example.com
        
        Previous message content.
      EMAIL
      
      threads = parser.split_in_threads(email_text)
      expect(threads).to be_an(Array)
      expect(threads.length).to be >= 1
    end

    it 'splits email with spanish markers' do
      email_text = <<~EMAIL
        Mensaje original aquí.
        
        -----Mensaje original-----
        De: remitente@example.com
        Para: destinatario@example.com

        Contenido del mensaje anterior.
      EMAIL

      threads = parser.split_in_threads(email_text)
      expect(threads).to be_an(Array)
      expect(threads.length).to be >= 1 
    end

    it 'splits the email if a name is present but no email in the marker' do
      email_text = <<~EMAIL
        original message.

        -----Original Message-----
        From: John Doe
        To: Jane Doe

        Previous message content.
      EMAIL

      threads = parser.split_in_threads(email_text)
      expect(threads).to be_an(Array)
      expect(threads.length).to be >= 1
    end

    it 'returns single message when no thread markers' do
      email_text = "Simple email without thread markers."
      threads = parser.split_in_threads(email_text)
      expect(threads).to eq([email_text.strip])
    end
  end

  describe '#remove_forwarded_content' do
    it 'removes forwarded content markers' do
      email_text = <<~EMAIL
        Original content here.
        
        ---------- Forwarded message ----------
        From: someone@example.com
        Forwarded content that should be removed.
      EMAIL
      
      cleaned = parser.remove_forwarded_content(email_text)
      expect(cleaned).not_to include("Forwarded message")
      expect(cleaned).not_to include("Forwarded content that should be removed")
    end

    it 'handles multiple forwarded sections' do
      email_text = <<~EMAIL
        Original content here.
        
        ---------- Forwarded message ----------
        From: someone@example.com
        Forwarded content that should be removed.
        ---------- Forwarded message ----------
        More original content.
      EMAIL

      cleaned = parser.remove_forwarded_content(email_text)
      expect(cleaned).not_to include("Forwarded message")
      expect(cleaned).not_to include("Forwarded content that should be removed")
      expect(cleaned).not_to include("More original content.")
      expect(cleaned).to include("Original content here.")
    end

    it 'handles forwarded content in spanish' do
      email_text = <<~EMAIL
        Contenido original aquí.
        
        ---------- Mensaje reenviado ----------
        De: alguien@example.com
        Contenido reenviado que debe ser eliminado.
      EMAIL

      cleaned = parser.remove_forwarded_content(email_text)
      expect(cleaned).not_to include("Mensaje reenviado")
      expect(cleaned).not_to include("Contenido reenviado que debe ser eliminado.")
      expect(cleaned).to include("Contenido original aquí.")
    end
    
    it 'returns original text when no forwarded content' do
      email_text = "Regular email content without forwarding."
      cleaned = parser.remove_forwarded_content(email_text)
      expect(cleaned).to eq(email_text)
    end

    it 'should not remove forwarded content if not enough slashes' do
      email_text = <<~EMAIL
        Original content here.
        
        ---- Forwarded message ----
        From: alguien@example.com
        Contenido reenviado que debe ser eliminado.
      EMAIL

      cleaned = parser.remove_forwarded_content(email_text)
      expect(cleaned).to include("Original content here.")
      expect(cleaned).to include("---- Forwarded message ----")
      expect(cleaned).to include("From: alguien@example.com")
      expect(cleaned).to include("Contenido reenviado que debe ser eliminado.")
    end
  end

  describe '#parse_email_html' do
    context 'with valid HTML' do
      it 'extracts content from HTML tags' do
        html = '<html><body><p>Hello World</p></body></html>'
        result = parser.parse_email_html(html)
        expect(result).to include("Hello World")
      end
      
      it 'handles HTML with style tags' do
        html = '<html><head><style>body{color:red}</style></head><body>Content</body></html>'
        result = parser.parse_email_html(html)
        expect(result).to include("Content")
        expect(result).not_to include("body{color:red}")
      end

      it 'should include links' do
        html = '<html><body><p>Visit us at <a href="https://www.example.com">Example</a></p></body></html>'
        result = parser.parse_email_html(html)
        expect(result).to include("Visit us at")
        expect(result).to include("<a href=\"https://www.example.com\">Example</a>")
      end
    end
    
    context 'with invalid HTML' do
      it 'raises ParseError for malformed HTML' do
        html = '<html><body><p>Unclosed tag'
        expect { parser.parse_email_html(html) }.to raise_error(EmailSignatureParser::ParseError)
      end
      
      it 'raises ParseError for empty HTML' do
        expect { parser.parse_email_html("") }.to raise_error(EmailSignatureParser::ParseError)
      end
    end
  end

  describe '#get_signature_sentences' do
    let(:name) { "John Doe" }
    let(:email_address) { "john.doe@company.com" }
    
    it 'identifies signature sentences in email body, using the name' do
      email_body = <<~EMAIL
        Hi there,
        
        Thanks for your email.
        
        Best regards,
        John Doe
        Senior Developer
        Tech Company Inc.
        john.doe@company.com
        +1 (555) 123-4567
      EMAIL
      
      parser.get_signature_sentences(name, email_address, email_body)
      signature_sentences = parser.instance_variable_get(:@signature_sentences)
      
      expect(signature_sentences).to be_an(Array)
      expect(signature_sentences.length).to eq 5
      
    end
    it 'identifies signature sentences without name, deducing it from the email address' do
      email_body = <<~EMAIL
        Hi there,
        
        Thanks for your email.
        
        Best regards,
        John Doe
        Senior Developer
        Tech Company Inc.
        john.doe@company.com
        +1 (555) 123-4567
      EMAIL

      parser.get_signature_sentences("", 'jdoe@email.com', email_body)
      signature_sentences = parser.instance_variable_get(:@signature_sentences)
      parsed_name_from_signature = parser.instance_variable_get(:@parsed_name_from_signature)

      expect(signature_sentences).to be_an(Array)
      expect(signature_sentences.length).to eq 5
      expect(parsed_name_from_signature).to eq("John Doe")

      parser.get_signature_sentences("", 'jdoe@email.com', email_body)
      signature_sentences = parser.instance_variable_get(:@signature_sentences)

      expect(signature_sentences).to be_an(Array)
      expect(signature_sentences.length).to eq 5
      expect(parsed_name_from_signature).to eq("John Doe")

      parser.get_signature_sentences("", 'john.doe@email.com', email_body)
      signature_sentences = parser.instance_variable_get(:@signature_sentences)

      expect(signature_sentences).to be_an(Array)
      expect(signature_sentences.length).to eq 5
      expect(parsed_name_from_signature).to eq("John Doe")

      parser.get_signature_sentences("", 'john.doe@email.com', email_body)
      signature_sentences = parser.instance_variable_get(:@signature_sentences)

      expect(signature_sentences).to be_an(Array)
      expect(signature_sentences.length).to eq 5
      expect(parsed_name_from_signature).to eq("John Doe")
    end

    it 'identifies signature sentences without name, deducing it from the email address even with middle names' do
      email_body = <<~EMAIL
        Hi there,
        
        Thanks for your email.
        
        Best regards,
        John Middlename Doe
        Senior Developer
        Tech Company Inc.
        john.doe@company.com
        +1 (555) 123-4567
      EMAIL

      parser.get_signature_sentences("", 'jdoe@email.com', email_body)
      signature_sentences = parser.instance_variable_get(:@signature_sentences)
      parsed_name_from_signature = parser.instance_variable_get(:@parsed_name_from_signature)

      expect(signature_sentences).to be_an(Array)
      expect(signature_sentences.length).to eq 5
      expect(parsed_name_from_signature).to eq("John Middlename Doe")

      parser.get_signature_sentences("", 'jdoe@email.com', email_body)
      signature_sentences = parser.instance_variable_get(:@signature_sentences)

      expect(signature_sentences).to be_an(Array)
      expect(signature_sentences.length).to eq 5
      expect(parsed_name_from_signature).to eq("John Middlename Doe")

      parser.get_signature_sentences("", 'john.doe@email.com', email_body)
      signature_sentences = parser.instance_variable_get(:@signature_sentences)

      expect(signature_sentences).to be_an(Array)
      expect(signature_sentences.length).to eq 5
      expect(parsed_name_from_signature).to eq("John Middlename Doe")

      parser.get_signature_sentences("", 'john.doe@email.com', email_body)
      signature_sentences = parser.instance_variable_get(:@signature_sentences)

      expect(signature_sentences).to be_an(Array)
      expect(signature_sentences.length).to eq 5
      expect(parsed_name_from_signature).to eq("John Middlename Doe")

      parser.get_signature_sentences("", 'john.middlename.doe@email.com', email_body)
      signature_sentences = parser.instance_variable_get(:@signature_sentences)

      expect(signature_sentences).to be_an(Array)
      expect(signature_sentences.length).to eq 5
      expect(parsed_name_from_signature).to eq("John Middlename Doe")

      parser.get_signature_sentences("", 'johnmdoe@email.com', email_body)
      signature_sentences = parser.instance_variable_get(:@signature_sentences)

      expect(signature_sentences).to be_an(Array)
      expect(signature_sentences.length).to eq 5
      expect(parsed_name_from_signature).to eq("John Middlename Doe")

      parser.get_signature_sentences("", 'jmdoe@email.com', email_body)
      signature_sentences = parser.instance_variable_get(:@signature_sentences)

      expect(signature_sentences).to be_an(Array)
      expect(signature_sentences.length).to eq 5
      expect(parsed_name_from_signature).to eq("John Middlename Doe")

    end

    it 'identifies signature sentences by finding the email in the signature' do
      email_body = <<~EMAIL
        Hi there,
        
        Thanks for your email.
        
        Best regards,


        John Doe
        Senior Developer
        Tech Company Inc.
        contact@company.com
        +1 (555) 123-4567
      EMAIL

      parser.get_signature_sentences("", 'contact@company.com', email_body)
      signature_sentences = parser.instance_variable_get(:@signature_sentences)

      expect(signature_sentences).to be_an(Array)
      expect(signature_sentences.length).to eq 5

    end
    it 'does not find the signature if the email and the name do not match' do
      email_body = <<~EMAIL
        Hi there,
        
        Thanks for your email.
        
        Best regards,


        John Doe
        Senior Developer
        Tech Company Inc.
        contact@company.com
        +1 (555) 123-4567
      EMAIL

      parser.get_signature_sentences("", 'contact@other.com', email_body)
      signature_sentences = parser.instance_variable_get(:@signature_sentences)

      expect(signature_sentences).to be_an(Array)
      expect(signature_sentences.length).to eq 0

    end

    it 'identifies signature sentences using a partial name match' do
      email_body = <<~EMAIL
        Hi there,
        
        Thanks for your email.
        
        Best regards,
        John Middlename Doe
        Senior Developer
        Tech Company Inc.
        +1 (555) 123-4567
      EMAIL
      
      parser.get_signature_sentences("John Doe", email_address, email_body)
      signature_sentences = parser.instance_variable_get(:@signature_sentences)
      
      expect(signature_sentences).to be_an(Array)
      expect(signature_sentences.length).to eq 4
      
    end
  end

  describe '#get_address' do
    it 'extracts single line address' do
      parser.instance_variable_set(:@signature_sentences, 
      [
        { isSignature: true, doc: "John Doe", type: 'name' },
        { isSignature: true, doc: "123 Main Street, New York, NY 10001, USA", type: 'unknown' },
        { isSignature: true, doc: "Phone: +1 (555) 123-4567", type: 'unknown' },
      ])

      address = parser.get_address
      expect(address).to eq ('123 Main Street, New York, NY 10001, USA')
      signature_sentences = parser.instance_variable_get(:@signature_sentences)
      expect(signature_sentences.filter { |s| s[:type] == 'address' }.size).to eq 1

    end
    it 'extracts multiline address' do
      parser.instance_variable_set(:@signature_sentences, 
      [
        { isSignature: true, doc: "John Doe", type: 'name' },
        { isSignature: true, doc: "123 Main Street, New York", type: 'unknown' },
        { isSignature: true, doc: "NY 10001, USA", type: 'unknown' },
        { isSignature: true, doc: "Phone: +1 (555) 123-4567", type: 'unknown' },
      ])

      address = parser.get_address
      expect(address).to eq ('123 Main Street, New York, NY 10001, USA')
      signature_sentences = parser.instance_variable_get(:@signature_sentences)
      expect(signature_sentences.filter { |s| s[:type] == 'address' }.size).to eq 2
    end
    
    it 'returns empty string when no address found' do
      parser.instance_variable_set(:@signature_sentences, [
        { isSignature: true, doc: "John Doe", type: 'unknown' },
        { isSignature: true, doc: "Senior Developer", type: 'unknown' }
      ])
      
      address = parser.get_address
      expect(address).to eq ''

    end

    it 'Discards address if resulting string too long' do
      parser.instance_variable_set(:@signature_sentences, [
        { isSignature: true, doc: "John Doe", type: 'unknown' },
        { isSignature: true, doc: "123 Main Street, New York", type: 'unknown' },
        { isSignature: true, doc: "Additional Address Line That Makes It Way Too Long Additional Address Line That Makes It Way Too Long Additional Address Line That Makes It Way Too Long Additional Address Line That Makes It Way Too Long NY 10001, USA", type: 'unknown' },
        { isSignature: true, doc: "Phone: +1 (555) 123-4567", type: 'unknown' }
      ])
      address = parser.get_address
      expect(address).to eq ''
      signature_sentences = parser.instance_variable_get(:@signature_sentences)
      expect(signature_sentences.filter { |s| s[:type] == 'address' }.size).to eq 0
    end

    it 'discards an address if it has a number and main street, but no postcode or state' do
      parser.instance_variable_set(:@signature_sentences, [
        { isSignature: true, doc: "John Doe", type: 'unknown' },
        { isSignature: true, doc: "123 Main Street", type: 'unknown' },
        { isSignature: true, doc: "Phone: +1 (555) 123-4567", type: 'unknown' }
      ])
      address = parser.get_address
      expect(address).to eq ''
      signature_sentences = parser.instance_variable_get(:@signature_sentences)
      expect(signature_sentences.filter { |s| s[:type] == 'address' }.size).to eq 0
    end

    it 'Gets an address with a number, street and city' do
      parser.instance_variable_set(:@signature_sentences, [
        { isSignature: true, doc: "John Doe", type: 'unknown' },
        { isSignature: true, doc: "221B Baker Street, NW1 6XE, London", type: 'unknown' },
        { isSignature: true, doc: "Phone: +1 (555) 123-4567", type: 'unknown' }
      ])
      address = parser.get_address
      expect(address).to eq "221B Baker Street, NW1 6XE, London"
      signature_sentences = parser.instance_variable_get(:@signature_sentences)
      expect(signature_sentences.filter { |s| s[:type] == 'address' }.size).to eq 1
    end
    it 'Gets an address with a postcode and a city' do
      parser.instance_variable_set(:@signature_sentences, [
        { isSignature: true, doc: "John Doe", type: 'unknown' },
        { isSignature: true, doc: "NW1 6XE, London", type: 'unknown' },
        { isSignature: true, doc: "Phone: +1 (555) 123-4567", type: 'unknown' }
      ])
      address = parser.get_address
      expect(address).to eq "NW1 6XE, London"
      signature_sentences = parser.instance_variable_get(:@signature_sentences)
      expect(signature_sentences.filter { |s| s[:type] == 'address' }.size).to eq 1
    end

    it 'Gets an address with a city and a country' do
      parser.instance_variable_set(:@signature_sentences, [
        { isSignature: true, doc: "John Doe", type: 'unknown' },
        { isSignature: true, doc: "London, UK", type: 'unknown' },
        { isSignature: true, doc: "Phone: +1 (555) 123-4567", type: 'unknown' }
      ])
      address = parser.get_address
      expect(address).to eq "London, UK"
      signature_sentences = parser.instance_variable_get(:@signature_sentences)
      expect(signature_sentences.filter { |s| s[:type] == 'address' }.size).to eq 1
    end

    it 'It should remove any links from the address' do
      parser.instance_variable_set(:@signature_sentences, [
        { isSignature: true, doc: "John Doe", type: 'unknown' },
        { isSignature: true, doc: "221B Baker Street, NW1 6XE, London <a href=\"https://maps.google.com/?q=221B+Baker+Street,+NW1+6XE,+London\">221B Baker Street, NW1 6XE, London</a>", type: 'unknown' },
        { isSignature: true, doc: "Phone: +1 (555) 123-4567", type: 'unknown' }
      ])
      address = parser.get_address
      expect(address).to eq "221B Baker Street, NW1 6XE, London"
      signature_sentences = parser.instance_variable_get(:@signature_sentences)
      expect(signature_sentences.filter { |s| s[:type] == 'address' }.size).to eq 1 
    end
  end

  describe '#get_phones' do
    
    it 'extracts phone numbers from signature sentences' do
      parser.instance_variable_set(:@signature_sentences, [
        { isSignature: true, doc: "John Doe", type: 'unknown' },
        { isSignature: true, doc: "123 Main Street, New York", type: 'unknown' },
        { isSignature: true, doc: "Phone: (555) 123-4567", type: 'unknown' },
        { isSignature: true, doc: "Mobile: (555) 987-6543", type: 'unknown' },
        { isSignature: true, doc: "Work: (555) 555-5555", type: 'unknown' },
        { isSignature: true, doc: "Fax: (555) 555-1234", type: 'unknown' },
        { isSignature: true, doc: "Direct Line: (555) 555-0000", type: 'unknown' }
      ])

      phones = parser.get_phones

      expect(phones).to be_an(Array)
      
      expect(phones.length).to eq 5
      phone = phones.find { |p| p[:type] == 'Phone' }
      expect(phone).not_to be_nil
      expect(phone[:phone_number]).to eq('(555) 123-4567')
      expect(phone[:country]).to be_nil

      mobile = phones.find { |p| p[:type] == 'Mobile' }
      expect(mobile).not_to be_nil
      expect(mobile[:phone_number]).to eq('(555) 987-6543')
      expect(mobile[:country]).to be_nil

      office = phones.find { |p| p[:type] == 'Office' }
      expect(office).not_to be_nil
      expect(office[:phone_number]).to eq('(555) 555-5555')
      expect(office[:country]).to be_nil

      fax = phones.find { |p| p[:type] == 'Fax' }
      expect(fax).not_to be_nil
      expect(fax[:phone_number]).to eq('(555) 555-1234')
      expect(fax[:country]).to be_nil

      direct = phones.find { |p| p[:type] == 'Direct Line' }
      expect(direct).not_to be_nil
      expect(direct[:phone_number]).to eq('(555) 555-0000')
      expect(direct[:country]).to be_nil
    end

    it 'should return a phone with the country if the number includes it' do
      parser.instance_variable_set(:@signature_sentences, [
        { isSignature: true, doc: "John Doe", type: 'unknown' },
        { isSignature: true, doc: "221B Baker Street, NW1 6XE, London", type: 'unknown' },
        { isSignature: true, doc: "Phone: +44 20 7946 0958", type: 'unknown' },
      ])
      phones = parser.get_phones
      expect(phones).to be_an(Array)
      expect(phones.length).to eq 1
      phone = phones.first
      expect(phone[:type]).to eq('Phone')
      expect(phone[:phone_number]).to eq('+44 20 7946 0958')
      expect(phone[:country]).to eq('GB')
    end

    it 'should extract an extension if present' do
      parser.instance_variable_set(:@signature_sentences, [
        { isSignature: true, doc: "John Doe", type: 'unknown' },
        { isSignature: true, doc: "221B Baker Street, NW1 6XE, London", type: 'unknown' },
        { isSignature: true, doc: "Phone: +44 20 7946 0958 ext. 123", type: 'unknown' },
        { isSignature: true, doc: "Mobile: +44 (20) 7946-0999 x444", type: 'unknown' },

      ])
      phones = parser.get_phones
      expect(phones).to be_an(Array)
      expect(phones.length).to eq 2
      phone = phones.find { |p| p[:type] == 'Phone' }
      expect(phone[:phone_number]).to eq('+44 20 7946 0958')
      expect(phone[:extension]).to eq('123')  
      mobile = phones.find { |p| p[:type] == 'Mobile' }
      expect(mobile[:phone_number]).to eq('+44 (20) 7946-0999')
      expect(mobile[:extension]).to eq('444')
    end
    it 'should extract an extension even if its written after a comma' do
      parser.instance_variable_set(:@signature_sentences, [
        { isSignature: true, doc: "John Doe", type: 'unknown' },
        { isSignature: true, doc: "221B Baker Street, NW1 6XE, London", type: 'unknown' },
        { isSignature: true, doc: "Phone: +44 20 7946 0958, ext. 123", type: 'unknown' },

      ])
      phones = parser.get_phones
      expect(phones).to be_an(Array)
      expect(phones.length).to eq 1
      phone = phones.find { |p| p[:type] == 'Phone' }
      expect(phone[:phone_number]).to eq('+44 20 7946 0958')
      expect(phone[:extension]).to eq('123')
    end

    it 'returns empty array when no phones in signature' do
      parser.instance_variable_set(:@signature_sentences, [
        { isSignature: true, doc: "John Doe", type: 'unknown' },
        { isSignature: true, doc: "Senior Developer", type: 'unknown' }
      ])
      
      phones = parser.get_phones
      expect(phones).to be_an(Array)
      expect(phones.length).to eq 0
    end

    it 'it labels phones if the label is after the number' do
      parser.instance_variable_set(:@signature_sentences, [
        { isSignature: true, doc: "John Doe", type: 'unknown' },
        { isSignature: true, doc: "221B Baker Street, NW1 6XE, London", type: 'unknown' },
        { isSignature: true, doc: "+44 20 7946 0958 Phone", type: 'unknown' },
        { isSignature: true, doc: "+44 (20) 7946-0999 Mobile", type: 'unknown' },
        { isSignature: true, doc: "+44 20 7946 0958 Office x123", type: 'unknown' },
        { isSignature: true, doc: "+44 20 7946 0726 Fax", type: 'unknown' },
        { isSignature: true, doc: "+44 20 7946 0706 Direct Line", type: 'unknown' },

      ])
      phones = parser.get_phones
      expect(phones).to be_an(Array)
      expect(phones.length).to eq 5
      phone = phones.find { |p| p[:type] == 'Phone' }
      expect(phone[:phone_number]).to eq('+44 20 7946 0958')
      expect(phone[:extension]).to be_nil  
      mobile = phones.find { |p| p[:type] == 'Mobile' }
      expect(mobile[:phone_number]).to eq('+44 (20) 7946-0999')
      expect(mobile[:extension]).to be_nil
      office = phones.find { |p| p[:type] == 'Office' }
      expect(office[:phone_number]).to eq('+44 20 7946 0958')
      expect(office[:extension]).to eq('123')
      fax = phones.find { |p| p[:type] == 'Fax' }
      expect(fax[:phone_number]).to eq('+44 20 7946 0726')
      expect(fax[:extension]).to be_nil
      direct = phones.find { |p| p[:type] == 'Direct Line' }
      expect(direct[:phone_number]).to eq('+44 20 7946 0706')
      expect(direct[:extension]).to be_nil
    end
  end

  describe '#get_links' do
    
    it 'extracts links from signature sentences' do
      parser.instance_variable_set(:@signature_sentences, [
        { isSignature: true, doc: "John Doe", type: 'unknown' },
        { isSignature: true, doc: "221B Baker Street, NW1 6XE", type: 'unknown' },
        { isSignature: true, doc: "Phone: +1 (555) 123-4567", type: 'unknown' },
        { isSignature: true, doc: "Visit us at <a href=\"https://www.company.com\">company.com</a>", type: 'unknown' },
        { isSignature: true, doc: "LinkedIn: <a href=\"https://linkedin.com/in/johndoe\">LinkedIn</a>", type: 'unknown' },
        { isSignature: true, doc: "Follow us on <a href=\"https://twitter.com/company\">Twitter</a>", type: 'unknown' },
      ])
      
      links = parser.get_links

      expect(links[:other].size).to eq 1
      expect(links[:other]).to include('https://www.company.com')
      expect(links[:social_media][:linkedin]).to include('https://linkedin.com/in/johndoe')
      expect(links[:social_media][:twitter]).to include('https://twitter.com/company')
    end

    it 'fills https if not present in link' do
      parser.instance_variable_set(:@signature_sentences, [
        { isSignature: true, doc: "John Doe", type: 'unknown' },
        { isSignature: true, doc: "221B Baker Street, NW1 6XE", type: 'unknown' },
        { isSignature: true, doc: "Phone: +1 (555) 123-4567", type: 'unknown' },
        { isSignature: true, doc: "Visit us at <a href=\"company.com\">company.com</a>", type: 'unknown' },
        { isSignature: true, doc: "LinkedIn: <a href=\"https://linkedin.com/in/johndoe\">LinkedIn</a>", type: 'unknown' },
        { isSignature: true, doc: "Follow us on <a href=\"https://twitter.com/company\">Twitter</a>", type: 'unknown' },
      ])

      links = parser.get_links
      expect(links[:other].size).to eq 1
      expect(links[:other]).to include('https://company.com')
    end

    it 'extract social media links' do
      parser.instance_variable_set(:@signature_sentences, [
        { isSignature: true, doc: "John Doe", type: 'unknown' },
        { isSignature: true, doc: "221B Baker Street, NW1 6XE", type: 'unknown' },
        { isSignature: true, doc: "Phone: +1 (555) 123-4567", type: 'unknown' },
        { isSignature: true, doc: "Visit us at <a href=\"company.com\">company.com</a>", type: 'unknown' },
        { isSignature: true, doc: "LinkedIn: <a href=\"https://linkedin.com/in/johndoe\">LinkedIn</a>", type: 'unknown' },
        { isSignature: true, doc: "Follow us on <a href=\"https://twitter.com/company\">Twitter</a>", type: 'unknown' },
        { isSignature: true, doc: "Facebook page: <a href=\"https://facebook.com/company\">Facebook</a>", type: 'unknown' },
        { isSignature: true, doc: "Instagram: <a href=\"https://instagram.com/company\">Instagram</a>", type: 'unknown' },
        { isSignature: true, doc: "Youtube: <a href=\"https://youtube.com/company\">Youtube</a>", type: 'unknown' },
        { isSignature: true, doc: "TikTok: <a href=\"https://tiktok.com/company\">TikTok</a>", type: 'unknown' },
        { isSignature: true, doc: "X: <a href=\"https://x.com/company\">X</a>", type: 'unknown' },
        { isSignature: true, doc: "Bluesky: <a href=\"https://bsky.com/company\">Bluesky</a>", type: 'unknown' },
      ])

      links = parser.get_links
      expect(links[:social_media][:linkedin]).to include('https://linkedin.com/in/johndoe')
      expect(links[:social_media][:twitter]).to include('https://twitter.com/company')
      expect(links[:social_media][:facebook]).to include('https://facebook.com/company')
      expect(links[:social_media][:instagram]).to include('https://instagram.com/company')
      expect(links[:social_media][:youtube]).to include('https://youtube.com/company')
      expect(links[:social_media][:tiktok]).to include('https://tiktok.com/company')
      expect(links[:social_media][:x]).to include('https://x.com/company')
      expect(links[:social_media][:bsky]).to include('https://bsky.com/company')
    end
    
    it 'returns empty array when no links in signature' do
      parser.instance_variable_set(:@signature_sentences, [
        { isSignature: true, doc: "John Doe", type: 'unknown' },
        { isSignature: true, doc: "Senior Developer", type: 'unknown' }
      ])
      
      links = parser.get_links
      expect(links).to be_a(Hash)
      expect(links[:social_media]).to be_a(Hash)
      expect(links[:other]).to be_a(Array)
      expect(links[:social_media].keys.length).to eq 0
      expect(links[:other].length).to eq 0
    end
  end

  describe '#get_company_name_and_job_title' do
    
    it 'extracts job title and company name' do

      parser.instance_variable_set(:@signature_sentences, [
        { isSignature: true, doc: "John Doe", type: 'unknown' },
        { isSignature: true, doc: "Senior Developer", type: 'unknown' },
        { isSignature: true, doc: "Tech Company", type: 'unknown' },
        { isSignature: true, doc: "221B Baker Street, NW1 6XE", type: 'unknown' },
        { isSignature: true, doc: "Phone: +1 (555) 123-4567", type: 'unknown' },
        { isSignature: true, doc: "Visit us at <a href=\"https://www.company.com\">company.com</a>", type: 'unknown' },
        { isSignature: true, doc: "LinkedIn: <a href=\"https://linkedin.com/in/johndoe\">LinkedIn</a>", type: 'unknown' },
        { isSignature: true, doc: "Follow us on <a href=\"https://twitter.com/company\">Twitter</a>", type: 'unknown' },
      ])
      
      company_name, job_title = parser.get_company_name_and_job_title("jdoe@techcompany.com")

      expect(job_title[:title]).to eq('Senior Developer')
      expect(company_name).to eq('Tech Company')
    end

    it 'extracts company name with a common suffix match' do

      parser.instance_variable_set(:@signature_sentences, [
        { isSignature: true, doc: "John Doe", type: 'unknown' },
        { isSignature: true, doc: "Senior Developer", type: 'unknown' },
        { isSignature: true, doc: "Tech Company Inc.", type: 'unknown' },
        { isSignature: true, doc: "221B Baker Street, NW1 6XE", type: 'unknown' },
        { isSignature: true, doc: "Phone: +1 (555) 123-4567", type: 'unknown' },
        { isSignature: true, doc: "Visit us at <a href=\"https://www.company.com\">company.com</a>", type: 'unknown' },
        { isSignature: true, doc: "LinkedIn: <a href=\"https://linkedin.com/in/johndoe\">LinkedIn</a>", type: 'unknown' },
        { isSignature: true, doc: "Follow us on <a href=\"https://twitter.com/company\">Twitter</a>", type: 'unknown' },
      ])
      
      company_name, job_title = parser.get_company_name_and_job_title("jdoe@techcom.com")

      expect(job_title[:title]).to eq('Senior Developer')
      expect(company_name).to eq('Tech Company Inc.')
    end

    it 'extracts company name with a similarity match' do

      parser.instance_variable_set(:@signature_sentences, [
        { isSignature: true, doc: "John Doe", type: 'unknown' },
        { isSignature: true, doc: "Senior Developer", type: 'unknown' },
        { isSignature: true, doc: "TechComp Developers", type: 'unknown' },
        { isSignature: true, doc: "221B Baker Street, NW1 6XE", type: 'unknown' },
        { isSignature: true, doc: "Phone: +1 (555) 123-4567", type: 'unknown' },
        { isSignature: true, doc: "Visit us at <a href=\"https://www.company.com\">company.com</a>", type: 'unknown' },
        { isSignature: true, doc: "LinkedIn: <a href=\"https://linkedin.com/in/johndoe\">LinkedIn</a>", type: 'unknown' },
        { isSignature: true, doc: "Follow us on <a href=\"https://twitter.com/company\">Twitter</a>", type: 'unknown' },
      ])
      
      company_name, job_title = parser.get_company_name_and_job_title("jdoe@techcom.com")

      expect(job_title[:title]).to eq('Senior Developer')
      expect(company_name).to eq('TechComp Developers')
    end

    it 'extracts partial company name with a similarity match' do

      parser.instance_variable_set(:@signature_sentences, [
        { isSignature: true, doc: "John Doe", type: 'unknown' },
        { isSignature: true, doc: "Senior Developer", type: 'unknown' },
        { isSignature: true, doc: "TechComp Developers and Software", type: 'unknown' },
        { isSignature: true, doc: "221B Baker Street, NW1 6XE", type: 'unknown' },
        { isSignature: true, doc: "Phone: +1 (555) 123-4567", type: 'unknown' },
        { isSignature: true, doc: "Visit us at <a href=\"https://www.company.com\">company.com</a>", type: 'unknown' },
        { isSignature: true, doc: "LinkedIn: <a href=\"https://linkedin.com/in/johndoe\">LinkedIn</a>", type: 'unknown' },
        { isSignature: true, doc: "Follow us on <a href=\"https://twitter.com/company\">Twitter</a>", type: 'unknown' },
      ])
      
      company_name, job_title = parser.get_company_name_and_job_title("jdoe@techcom.com")

      expect(job_title[:title]).to eq('Senior Developer')
      expect(company_name).to eq('TechComp')
    end
    it 'extracts job title in the same line as the name' do

      parser.instance_variable_set(:@signature_sentences, [
        { isSignature: true, doc: "John Doe, Senior Developer", type: 'unknown' },
        { isSignature: true, doc: "Tech Company Inc.", type: 'unknown' },
        { isSignature: true, doc: "221B Baker Street, NW1 6XE", type: 'unknown' },
        { isSignature: true, doc: "Phone: +1 (555) 123-4567", type: 'unknown' },
        { isSignature: true, doc: "Visit us at <a href=\"https://www.company.com\">company.com</a>", type: 'unknown' },
        { isSignature: true, doc: "LinkedIn: <a href=\"https://linkedin.com/in/johndoe\">LinkedIn</a>", type: 'unknown' },
        { isSignature: true, doc: "Follow us on <a href=\"https://twitter.com/company\">Twitter</a>", type: 'unknown' },
      ])
      
      company_name, job_title = parser.get_company_name_and_job_title("jdoe@techcompany.com")

      expect(job_title[:title]).to eq('Senior Developer')
      expect(company_name).to eq('Tech Company Inc.')
    end

    it 'handles multiple job titles' do
      parser.instance_variable_set(:@signature_sentences, [
        { isSignature: true, doc: "John Doe, Vice President of Sales", type: 'unknown' },
        { isSignature: true, doc: "Senior Developer", type: 'unknown' },
        { isSignature: true, doc: "Tech Company Inc.", type: 'unknown' },
        { isSignature: true, doc: "221B Baker Street, NW1 6XE", type: 'unknown' },
        { isSignature: true, doc: "Phone: +1 (555) 123-4567", type: 'unknown' },
        { isSignature: true, doc: "Visit us at <a href=\"https://www.company.com\">company.com</a>", type: 'unknown' },
        { isSignature: true, doc: "LinkedIn: <a href=\"https://linkedin.com/in/johndoe\">LinkedIn</a>", type: 'unknown' },
        { isSignature: true, doc: "Follow us on <a href=\"https://twitter.com/company\">Twitter</a>", type: 'unknown' },
      ])
      
      company_name, job_title = parser.get_company_name_and_job_title("jdoe@techcompany.com")

      expect(job_title[:titles]).to eq(['Vice President of Sales', 'Senior Developer'])
      expect(company_name).to eq('Tech Company Inc.')
    end
    it 'handles a job acronym' do
      parser.instance_variable_set(:@signature_sentences, [
        { isSignature: true, doc: "John Doe", type: 'unknown' },
        { isSignature: true, doc: "CTO", type: 'unknown' },
        { isSignature: true, doc: "Tech Company Inc.", type: 'unknown' },
        { isSignature: true, doc: "221B Baker Street, NW1 6XE", type: 'unknown' },
        { isSignature: true, doc: "Phone: +1 (555) 123-4567", type: 'unknown' },
        { isSignature: true, doc: "Visit us at <a href=\"https://www.company.com\">company.com</a>", type: 'unknown' },
        { isSignature: true, doc: "LinkedIn: <a href=\"https://linkedin.com/in/johndoe\">LinkedIn</a>", type: 'unknown' },
        { isSignature: true, doc: "Follow us on <a href=\"https://twitter.com/company\">Twitter</a>", type: 'unknown' },
      ])
      
      company_name, job_title = parser.get_company_name_and_job_title("jdoe@techcompany.com")

      expect(job_title[:acronym]).to eq('CTO')
      expect(company_name).to eq('Tech Company Inc.')
    end

    it 'handles an acronym in the same line as the name' do
      parser.instance_variable_set(:@signature_sentences, [
        { isSignature: true, doc: "John Doe, CFO", type: 'unknown' },
        { isSignature: true, doc: "Tech Company Inc.", type: 'unknown' },
        { isSignature: true, doc: "221B Baker Street, NW1 6XE", type: 'unknown' },
        { isSignature: true, doc: "Phone: +1 (555) 123-4567", type: 'unknown' },
        { isSignature: true, doc: "Visit us at <a href=\"https://www.company.com\">company.com</a>", type: 'unknown' },
        { isSignature: true, doc: "LinkedIn: <a href=\"https://linkedin.com/in/johndoe\">LinkedIn</a>", type: 'unknown' },
        { isSignature: true, doc: "Follow us on <a href=\"https://twitter.com/company\">Twitter</a>", type: 'unknown' },
      ])
      
      company_name, job_title = parser.get_company_name_and_job_title("jdoe@techcompany.com")

      expect(job_title[:acronym]).to eq('CFO')
      expect(company_name).to eq('Tech Company Inc.')
    end

    it 'handles multiple acronyms' do
      parser.instance_variable_set(:@signature_sentences, [
        { isSignature: true, doc: "John Doe, MSc, PhD", type: 'unknown' },
        { isSignature: true, doc: "Tech Company Inc.", type: 'unknown' },
        { isSignature: true, doc: "221B Baker Street, NW1 6XE", type: 'unknown' },
        { isSignature: true, doc: "Phone: +1 (555) 123-4567", type: 'unknown' },
        { isSignature: true, doc: "Visit us at <a href=\"https://www.company.com\">company.com</a>", type: 'unknown' },
        { isSignature: true, doc: "LinkedIn: <a href=\"https://linkedin.com/in/johndoe\">LinkedIn</a>", type: 'unknown' },
        { isSignature: true, doc: "Follow us on <a href=\"https://twitter.com/company\">Twitter</a>", type: 'unknown' },
      ])
      
      company_name, job_title = parser.get_company_name_and_job_title("jdoe@techcompany.com")

      expect(job_title[:acronyms]).to eq(['MSc', 'PhD'])
      expect(company_name).to eq('Tech Company Inc.')
    end

    it 'it ignores lines that dont look like the company name or a title' do
      parser.instance_variable_set(:@signature_sentences, [
        { isSignature: true, doc: "John Doe", type: 'unknown' },
        { isSignature: true, doc: "221B Baker Street, NW1 6XE", type: 'unknown' },
        { isSignature: true, doc: "Phone: +1 (555) 123-4567", type: 'unknown' },
        { isSignature: true, doc: "Visit us at <a href=\"https://www.company.com\">company.com</a>", type: 'unknown' },
        { isSignature: true, doc: "LinkedIn: <a href=\"https://linkedin.com/in/johndoe\">LinkedIn</a>", type: 'unknown' },
        { isSignature: true, doc: "Follow us on <a href=\"https://twitter.com/company\">Twitter</a>", type: 'unknown' },
      ])

      company_name, job_title = parser.get_company_name_and_job_title("jdoe@techcompany.com")
      expect(job_title.keys.size).to eq(0)
      expect(company_name).to eq('')
    end
  end

  describe '#parse_signature' do
    
    it 'returns complete signature hash' do
      email_body = <<~EMAIL
        Hi there,
        
        Thanks for your message.
        
        Best regards,
        John Doe
        Senior Developer
        Tech Company Inc.
        123 Main Street, Suite 100
        New York, NY 10001
        Phone: +1 (555) 123-4567
        Email: john.doe@company.com
        Website: <a href="https://www.techcompany.com">https://www.techcompany.com</a>
      EMAIL

      signature = parser.parse_signature("John Doe", "jdoe@techcompany.com", email_body)
      
      expect(signature).to be_a(Hash)
      
      expect(signature[:name]).to eq("John Doe")
      expect(signature[:email_address]).to eq("jdoe@techcompany.com")
      expect(signature[:phones]).to be_an(Array) 
      expect(signature[:phones].first[:phone_number]).to eq("+1 (555) 123-4567")
      expect(signature[:address]).to eq("123 Main Street, Suite 100, New York, NY 10001")
      expect(signature[:job_title][:title]).to eq("Senior Developer")
      expect(signature[:company_name]).to eq("Tech Company Inc.")
      expect(signature[:links][:other]).to include("https://www.techcompany.com")
      expect(signature[:links][:social_media]).to be_a(Hash)
      expect(signature[:links][:social_media]).to be_empty
    end
    
    it 'deduces the name from the email address' do
      email_body = <<~EMAIL
        Hi there,
        
        Thanks for your message.
        
        Best regards,
        John Doe
        Senior Developer
        Tech Company Inc.
        123 Main Street, Suite 100
        New York, NY 10001
        Phone: +1 (555) 123-4567
        Email: john.doe@company.com
        Website: <a href="https://www.techcompany.com">https://www.techcompany.com</a>
      EMAIL

      signature = parser.parse_signature("", "jdoe@techcompany.com", email_body)
      
      expect(signature).to be_a(Hash)
      
      expect(signature[:name]).to eq("John Doe")
      expect(signature[:email_address]).to eq("jdoe@techcompany.com")
      expect(signature[:phones]).to be_an(Array) 
      expect(signature[:phones].first[:phone_number]).to eq("+1 (555) 123-4567")
      expect(signature[:address]).to eq("123 Main Street, Suite 100, New York, NY 10001")
      expect(signature[:job_title][:title]).to eq("Senior Developer")
      expect(signature[:company_name]).to eq("Tech Company Inc.")
      expect(signature[:links][:other]).to include("https://www.techcompany.com")
      expect(signature[:links][:social_media]).to be_a(Hash)
      expect(signature[:links][:social_media]).to be_empty
    end

    it 'deduces the name' do
      email_body = <<~EMAIL
        Hi there,
        
        Thanks for your message.
        Best regards,

        
        John Doe
        Senior Developer
        Tech Company Inc.
        123 Main Street, Suite 100
        New York, NY 10001
        Phone: +1 (555) 123-4567
        Email: contact@techcompany.com
        Website: <a href="https://www.techcompany.com">https://www.techcompany.com</a>
      EMAIL

      signature = parser.parse_signature("", "contact@techcompany.com", email_body)
      
      expect(signature).to be_a(Hash)
      
      expect(signature[:name]).to eq("John Doe")
      expect(signature[:email_address]).to eq("contact@techcompany.com")
      expect(signature[:phones]).to be_an(Array) 
      expect(signature[:phones].first[:phone_number]).to eq("+1 (555) 123-4567")
      expect(signature[:address]).to eq("123 Main Street, Suite 100, New York, NY 10001")
      expect(signature[:job_title][:title]).to eq("Senior Developer")
      expect(signature[:company_name]).to eq("Tech Company Inc.")
      expect(signature[:links][:other]).to include("https://www.techcompany.com")
      expect(signature[:links][:social_media]).to be_a(Hash)
      expect(signature[:links][:social_media]).to be_empty
    end
    
    it 'handles minimal signature' do
      minimal_body = <<~EMAIL
        Thanks,
        John
        john.doe@company.com
      EMAIL
      
      signature = parser.parse_signature("John Doe", "jdoe@techcompany.com", minimal_body)
      
      expect(signature).to be_a(Hash)
      
      expect(signature[:name]).to eq("John Doe")
      expect(signature[:email_address]).to eq("jdoe@techcompany.com")
      expect(signature[:phones]).to be_an(Array) 
      expect(signature[:phones]).to be_empty
      expect(signature[:address]).to eq("")
      expect(signature[:job_title]).to be_a(Hash)
      expect(signature[:job_title]).to be_empty
      expect(signature[:company_name]).to eq("")
      expect(signature[:links][:other]).to be_an(Array)
      expect(signature[:links][:other]).to be_empty
      expect(signature[:links][:social_media]).to be_a(Hash)
      expect(signature[:links][:social_media]).to be_empty
    end
  end

  describe '#parse_from_text' do
    let(:from) { "John Doe <john.doe@company.com>" }
    let(:email_body) do
      <<~EMAIL
        Hello,
        
        This is a test email.
        
        Best regards,
        John Doe
        Senior Developer
        john.doe@company.com
        +1 (555) 123-4567
      EMAIL
    end
    
    it 'parses signature from plain text email' do
      signature = parser.parse_from_text(from, email_body)
      
      expect(signature).to be_a(Hash)
      expect(signature[:name]).to eq("John Doe")
      expect(signature[:email_address]).to eq("john.doe@company.com")
      expect(signature[:phones]).to be_an(Array) 
      expect(signature[:phones].first[:phone_number]).to eq("+1 (555) 123-4567")

    end
    
    it 'raises InvalidEmailError for invalid from' do
      expect { parser.parse_from_text("", email_body) }.to raise_error(EmailSignatureParser::InvalidFromError)
    end
    
    it 'raises ParseError for empty email body' do
      expect { parser.parse_from_text(from, "") }.to raise_error(EmailSignatureParser::InvalidEmailError)
    end
    
    it 'raises ParseError for meeting emails' do
      meeting_body = "Join our meeting: https://zoom.us/j/123456789"
      expect { parser.parse_from_text(from, meeting_body) }.to raise_error(EmailSignatureParser::ParseError)
    end
  end

  describe '#parse_from_html' do 
    let(:from) { "John Doe <john.doe@company.com>" }
    let(:html_body) do 
      <<~EMAIL
        <!DOCTYPE html>
        <html>
        <head>
          <meta charset="UTF-8">
        </head>
        <body>
            <p>Dear Client,</p>
            
            <p>I hope this email finds you well. I wanted to provide you with an update on our current project status.</p>
            
            <p>Best regards,</p>
            <p>John</p>
            <hr>
            <div style="font-family: Arial, sans-serif; font-size: 12px; color: #333;">
                <p style="margin: 0;"><strong>John Doe</strong>, <em>Senior Software Engineer</em>, <strong>Tech Solutions Inc.</strong></p>
                <p style="margin: 5px 0;">
                123 Business Ave, Suite 100
                San Francisco, CA 94105
                </p>
                
                <p style="margin: 5px 0;">
                <li>Phone: +1 (415) 555-0123</li>
                <li>Mobile: +1 (415) 555-0124</li>
                <li>Fax: +1 (415) 555-0125 </li>
                <li>Email:<a href="mailto:john.doe@company.com">john.doe@company.com</a></li> 
                <li>Website:<a href="https://www.techsolutions.com">https://www.techsolutions.com</a></li>
                </p>
            </div>
        </body>
      </html>
      EMAIL
      
    end
    
    it 'parses signature from HTML email' do
      signature = parser.parse_from_html(from, html_body)
      
      expect(signature).to be_a(Hash)
      expect(signature[:name]).to eq("John Doe")
      expect(signature[:email_address]).to eq("john.doe@company.com")
      expect(signature[:phones]).to be_an(Array) 
      expect(signature[:phones].find{ |p| p[:type] == "Phone" }[:phone_number]).to eq("+1 (415) 555-0123")
      expect(signature[:job_title][:title]).to eq("Senior Software Engineer")
    end
    
    it 'raises InvalidEmailError for invalid from' do
      expect { parser.parse_from_html("", html_body) }.to raise_error(EmailSignatureParser::InvalidFromError)
    end
    
    it 'raises ParseError for empty HTML body' do
      expect { parser.parse_from_html(from, "") }.to raise_error(EmailSignatureParser::InvalidEmailError)
    end

    it 'raises ParseError for meeting emails' do
      meeting_body = "<html> <body>Join our meeting: https://zoom.us/j/123456789</body></html>"
      expect { parser.parse_from_html(from, meeting_body) }.to raise_error(EmailSignatureParser::ParseError)
    end
  end

  describe '#parse_from_file' do

    it 'parses signature from a file' do
      file_path = File.join(File.dirname(__FILE__), '../fixtures/enron_sample.txt')
      signature = parser.parse_from_file(file_path)
      
      expect(signature).to be_a(Hash)
      expect(signature[:name]).to eq("Robert H. George")
      expect(signature[:email_address]).to eq("robert.h.george@enron.com")
      expect(signature[:phones]).to be_an(Array)
      expect(signature[:phones].filter{ |p| p[:type] == "Phone" }.map{ |p| p[:phone_number] }).to eq(["77002-7361", "(713) 345-4159"])
      expect(signature[:phones].find{ |p| p[:type] == "Fax" }[:phone_number]).to eq("(713) 646-3490")

      expect(signature[:address]).to eq("1400 Smith Street EB 3832, Houston Texas 77002-7361")
    end

    it "parses an spanish iso-8859-1 file that is quoted-printable" do
      file_path = File.join(File.dirname(__FILE__), '../fixtures/sample_iso_8859_quoted.eml')
      signature = parser.parse_from_file(file_path)
      
      expect(signature).to be_a(Hash)
      expect(signature[:name]).to eq("Alejandro Martínez")
      expect(signature[:email_address]).to eq("admin@ejemplo.com")
      expect(signature[:phones]).to be_an(Array)
      expect(signature[:phones].find{ |p| p[:type] == "Phone" }[:phone_number]).to eq("+34 91 555 12 34")

    end
  end

end