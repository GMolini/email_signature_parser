module EmailSignatureParser
  module Utils
  
    # Calculates the percentage of digits in a text, ignoring spaces and HTML links.
    def self.get_digits_percentage(text)
      text = text.gsub(/<a[^>]*>|<\/a>/, '') #remove links before counting digits
      total_digits = text.count('0123456789')
      total_spaces = text.count(' ')
      
      total_chars= text.size - total_spaces
      if total_chars == 0
        return {'total': 0, 'pct': 0}
      end
      return {'total': total_digits, 'pct': (total_digits.to_f / total_chars).round(2)}
    end

    # Merges small strings in an array to avoid single-character elements, useful for name parsing.
    def self.merge_small_strings(array)

      out_array = []
      array_invalid = true
      loops = 0

      while array_invalid && loops < 100
        out_array = []

        if array.size > 1 && !array.size.even?
          #If array is uneven, check if last elem needs merging
          last_items = array.last(2)

          should_merge = last_items.reduce(false){|acc, val| val.size == 1 || acc}
          if should_merge
            array = array[0..array.size - 3] + [last_items.join("")]
          end
        end

        #Check every two items if the need merging
        array.each_slice(2) do |slice|
          should_merge = slice.reduce(false){|acc, val| val.size == 1 || acc}

          if should_merge
            out_array << slice.join("")
          else
            out_array += slice
          end
        end

        array_invalid = out_array.reduce(false){|acc, val| val.size == 1 || acc} && out_array.size > 1
        array = out_array
        loops += 1
      end

      out_array
    end
  end
end