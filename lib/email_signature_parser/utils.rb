module EmailSignatureParser
  module Utils

    def self.max_consecutive_digits(text)
      return 0 if text.nil? || text.empty?
      
      # Replace gaps of 1-2 non-digit characters between digits with empty string
      # This effectively makes digits separated by small gaps appear consecutive
      processed_text = text.gsub(/(\d)[^\da-zA-Z]{1,2}(?=\d)/, '\1')
      
      # Find all sequences of consecutive digits
      digit_sequences = processed_text.scan(/\d+/)
      
      # Return the length of the longest sequence
      digit_sequences.map(&:length).max || 0
    end

  end
end