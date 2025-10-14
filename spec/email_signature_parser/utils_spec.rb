require 'spec_helper'

RSpec.describe EmailSignatureParser::Utils do
  
  describe '.max_consecutive_digits' do
    context 'with valid input containing digits' do
      it 'returns the length of the longest consecutive digit sequence' do
        text = "abc123def456ghi7890"
        expect(described_class.max_consecutive_digits(text)).to eq(4)
      end
      
      it 'handles single digit sequences' do
        text = "a1b2c3d4"
        expect(described_class.max_consecutive_digits(text)).to eq(1)
      end
      
      it 'handles multiple sequences of same length' do
        text = "123abc456def789"
        expect(described_class.max_consecutive_digits(text)).to eq(3)
      end
      
      it 'returns length of entire string when all digits' do
        text = "1234567890"
        expect(described_class.max_consecutive_digits(text)).to eq(10)
      end
      
      it 'handles mixed alphanumeric with leading digits' do
        text = "12345abc67def8"
        expect(described_class.max_consecutive_digits(text)).to eq(5)
      end
    end
    
    context 'with digits separated by small gaps' do
      it 'treats digits separated by 1 non-digit character as consecutive' do
        text = "1-2-3-4-5"
        expect(described_class.max_consecutive_digits(text)).to eq(5)
      end
      
      it 'treats digits separated by 2 non-digit characters as consecutive' do
        text = "1  2  3  4"
        expect(described_class.max_consecutive_digits(text)).to eq(4)
      end
      
      it 'handles phone number format' do
        text = "(555) 123-4567"
        expect(described_class.max_consecutive_digits(text)).to eq(10)
      end
      
      it 'handles credit card format' do
        text = "4444-5555-6666-7777"
        expect(described_class.max_consecutive_digits(text)).to eq(16)
      end
      
      it 'handles social security number format' do
        text = "123-45-6789"
        expect(described_class.max_consecutive_digits(text)).to eq(9)
      end
      
      it 'does not bridge gaps larger than 2 characters' do
        text = "123___456"
        expect(described_class.max_consecutive_digits(text)).to eq(3)
      end
      
      it 'handles mixed gap sizes' do
        text = "12-34___567-8"
        # 12-34 becomes 1234 (4 digits), 567-8 becomes 5678 (4 digits)
        expect(described_class.max_consecutive_digits(text)).to eq(4)
      end
    end
    
    context 'with complex patterns' do  
      it 'handles email signature with phone numbers' do
        text = "Call me at (555) 123-4567 or mobile +1-800-555-0199"
        expect(described_class.max_consecutive_digits(text)).to eq(11) # +1-800-555-0199
      end
      
      it 'handles address with zip codes' do
        text = "123 Main St, City 12345-6789, USA"
        expect(described_class.max_consecutive_digits(text)).to eq(9) # 12345-6789
      end
      
      it 'handles date formats' do
        text = "Meeting on 2024-12-25 at 3:30 PM"
        expect(described_class.max_consecutive_digits(text)).to eq(8) # 20241225
      end
      
      it 'handles URL with numbers' do
        text = "Visit https://example.com/page123/item456"
        expect(described_class.max_consecutive_digits(text)).to eq(3)
      end
    end
    
    context 'with edge cases' do
      it 'returns 0 for nil input' do
        expect(described_class.max_consecutive_digits(nil)).to eq(0)
      end
      
      it 'returns 0 for empty string' do
        expect(described_class.max_consecutive_digits("")).to eq(0)
      end
      
      it 'returns 0 for strings with no digits' do
        text = "Hello World! No numbers here."
        expect(described_class.max_consecutive_digits(text)).to eq(0)
      end
      
      it 'handles strings with only non-digit characters' do
        text = "!@#$%^&*()_+-=[]{}|;:,.<>?"
        expect(described_class.max_consecutive_digits(text)).to eq(0)
      end
      
      it 'handles whitespace and special characters' do
        text = "   1 2 3   "
        expect(described_class.max_consecutive_digits(text)).to eq(3)
      end
      
      it 'handles Unicode characters' do
        text = "数字123在这里456"
        expect(described_class.max_consecutive_digits(text)).to eq(3)
      end
    end
    
    context 'with real-world examples' do
      it 'handles typical email signature' do
        signature = <<~SIG
          John Doe
          Senior Developer  
          Phone: (555) 123-4567
          Mobile: +1-800-555-0199
          Fax: (555) 123-4568
          Address: 123 Main Street, Suite 100, New York, NY 10001-1234
        SIG
        expect(described_class.max_consecutive_digits(signature)).to eq(11)
      end
      
      it 'handles international phone formats' do
        text = "UK: +44 20 7946 0958, US: +1 (555) 123-4567"
        expect(described_class.max_consecutive_digits(text)).to eq(12)
      end
      
      it 'handles business registration numbers' do
        text = "Registration: 12-3456789, Tax ID: 98-7654321"
        expect(described_class.max_consecutive_digits(text)).to eq(9)
      end
      
      it 'handles multiple contact methods' do
        text = "Office: (555) 123-4567 x1234, Direct: (555) 987-6543"
        expect(described_class.max_consecutive_digits(text)).to eq(10)
      end
    end
    
    context 'with boundary conditions' do
      it 'handles very long digit sequences' do
        long_digits = "1" * 100
        expect(described_class.max_consecutive_digits(long_digits)).to eq(100)
      end
      
      it 'handles alternating patterns' do
        text = "1a2a3a4a5a6a7a8a9a0"
        expect(described_class.max_consecutive_digits(text)).to eq(1)
      end
      
      it 'handles gaps at the beginning and end' do
        text = "abc123-456def"
        expect(described_class.max_consecutive_digits(text)).to eq(6)
      end
      
      it 'handles single character gaps in long sequences' do
        text = "1-2-3-4-5-6-7-8-9-0-1-2-3-4-5"
        expect(described_class.max_consecutive_digits(text)).to eq(15)
      end
    end
  end
  
end
