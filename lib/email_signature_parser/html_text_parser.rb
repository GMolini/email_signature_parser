module EmailSignatureParser
  class HtmlTextParser < ::Ox::Sax
    attr_reader :parsed_text

    def initialize()
      @parsed_text = ''
      @discard = false
      @current_element = ''

      @current_list_index = -1
      @lists = []


      @table_columns = 0
      @parsing_link = false
      @link_text = ""
      @link_href = ""
    end

    def start_element(name)

      if name == :b || name == :strong
        @parsed_text << " "
      elsif name == :i || name == :em
        @parsed_text << " "
      end

      if name == :script || name == :style || name == :head || name == :meta || name == :title
        @discard = true
      else
        @discard = false
      end

      @current_element = name
      if name == :br
        @parsed_text << "\n"
      end
      if name== :hr
        @parsed_text << "\n-------------------------------------------------------------------------------------------------------------------------------------------------\n"
      end
      if name == :ul || name == :ol
        @parsed_text << "\n"
        @lists << {
          list_type: name,
          ordered_list_level: 1,
          ordered_list_type: "1", #If its an unordered list, this is not used. 
        }
      end

      if name == :a
        @parsing_link = true
        @link_text = ""
        @link_href = ""
      end
    end

    def end_element(name)
      @discard = false

      if name == :b || name == :strong
        @parsed_text << " "
      elsif name == :i || name == :em
        @parsed_text << " "
      end

      if name == :p || name == :div || name.match(/h[1-6]/) || name == :br || name == :hr || name == :table || name == :tr
        @parsed_text << "\n"
      end

      if name == :a
        @parsed_text << "<a href=\"#{@link_href}\">#{@link_text}</a>" #leave links in html format
        @parsing_link = false
        @link_text = ""
        @link_href = ""
      end

      if name == :li
        @parsed_text << "\n"
        if  @lists.last && @lists.last[:list_type] == :ol
          @lists.last[:ordered_list_level] += 1
        end
      end

      if name == :ul || name == :ol
        @lists.pop
      end
    end

    def attr(name, value)

      if (@current_element == :a && name == :href)
        @link_href << value
      end

      if (@current_element == :div && name == :style && value.match?(/border-\w*:\s*solid/))
        @parsed_text << "\n-------------------------------------------------------------------------------------------------------------------------------------------------\n"
      end

      if (@current_element == :ol && name == :start)
        @lists.last[:ordered_list_level] = value.to_i
      end
      if (@current_element == :ol && name == :type)
        @lists.last[:ordered_list_type] = value
      end
    end

    def attrs_done()
      if @current_element == :li
        current_list = @lists.last
        if current_list.nil?
          #sometimes we encounter a <li> outside of a list, so we just ignore it
          return
        end
        if @lists.size > 1
          # We are inside a nested list, so we need to indent
          @parsed_text << " " * 2 * (@lists.size - 1)
        end

        if current_list[:list_type] == :ol
          if current_list[:ordered_list_type] == "A"
            @parsed_text << "#{('A'.ord + current_list[:ordered_list_level] - 1).chr}. "
          elsif current_list[:ordered_list_type] == "a"
            @parsed_text << "#{('a'.ord + current_list[:ordered_list_level] - 1).chr}. "
          elsif current_list[:ordered_list_type] == "I"
            @parsed_text << "#{roman_numeral(current_list[:ordered_list_level])}. "
          elsif current_list[:ordered_list_type] == "i"
            @parsed_text << "#{roman_numeral(current_list[:ordered_list_level]).downcase}. "
          else
            @parsed_text << "#{current_list[:ordered_list_level]}. "
          end
        else
          @parsed_text << "* "
        end
      end

    end

    def text(value)
      if @parsing_link
        @link_text << value
        return
      end
      unless value.nil? || value.empty? || @discard
        if value.include?("-----------------------------")
          @parsed_text << "\n-------------------------------------------------------------------------------------------------------------------------------------------------\n"
        else
          @parsed_text << value
        end
      end
    end

    def postprocess()

      # remove linefeeds (\r\n and \r -> \n)
      @parsed_text.gsub!(/\r\n?/, "\n")

      # strip extra spaces
      @parsed_text.gsub!(/[ \t]*\302\240+[ \t]*/, " ") # non-breaking spaces -> spaces
      @parsed_text.gsub!(/\n[\t]+/, "\n") # space at start of lines
      @parsed_text.gsub!(/[ \t]+\n/, "\n") # space at end of lines


      @parsed_text = @parsed_text.split("\n").map(&:strip).join("\n") # strip lines

    end

    def roman_numeral(number)
      roman_mapping = {
        1000 => "M", 900 => "CM", 500 => "D", 400 => "CD", 100 => "C",
        90 => "XC", 50 => "L", 40 => "XL", 10 => "X", 9 => "IX",
        5 => "V", 4 => "IV", 1 => "I"
      }
      result = ""
      roman_mapping.each do |value, letter|
        result << letter * (number / value)
        number = number % value
      end
      result
    end
  end
end