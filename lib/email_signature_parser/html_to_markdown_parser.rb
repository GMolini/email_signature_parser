module EmailSignatureParser
  class HtmlToMarkdownParser < ::Ox::Sax
    attr_reader :parsed_text
    HTML_SPECIAL_ESCAPED_CHARACTERS = {
      '&lt;' => '<',
      '&gt;' => '>',
    }

    HTML_SPECIAL_CHARACTERS = {
      # Reserved
      '&amp;'     => '&',
      '&quot;'    => '"',
      '&apos;'    => "'",

      # ISO 8859-1 Symbols
      '&nbsp;'    => ' ',
      '&iexcl;'   => '¡',
      '&cent;'    => '¢',
      '&pound;'   => '£',
      '&curren;'  => '¤',
      '&yen;'     => '¥',
      '&brvbar;'  => '¦',
      '&sect;'    => '§',
      '&uml;'     => '¨',
      '&copy;'    => '©',
      '&ordf;'    => 'ª',
      '&laquo;'   => '«',
      '&not;'     => '¬',
      '&shy;'     => '',
      '&reg;'     => '®',
      '&macr;'    => '¯',
      '&deg;'     => '°',
      '&plusmn;'  => '±',
      '&sup2;'    => '²',
      '&sup3;'    => '³',
      '&acute;'   => '´',
      '&micro;'   => 'µ',
      '&para;'    => '¶',
      '&middot;'  => '·',
      '&cedil;'   => '¸',
      '&sup1;'    => '¹',
      '&ordm;'    => 'º',
      '&raquo;'   => '»',
      '&frac14;'  => '¼',
      '&frac12;'  => '½',
      '&frac34;'  => '¾',
      '&iquest;'  => '¿',
      '&times;'   => '×',
      '&divide;'  => '÷',

      # ISO 8859-1 Characters
      '&Agrave;'  => 'À',
      '&Aacute;'  => 'Á',
      '&Acirc;'   => 'Â',
      '&Atilde;'  => 'Ã',
      '&Auml;'    => 'Ä',
      '&Aring;'   => 'Å',
      '&AElig;'   => 'Æ',
      '&Ccedil;'  => 'Ç',
      '&Egrave;'  => 'È',
      '&Eacute;'  => 'É',
      '&Ecirc;'   => 'Ê',
      '&Euml;'    => 'Ë',
      '&Igrave;'  => 'Ì',
      '&Iacute;'  => 'Í',
      '&Icirc;'   => 'Î',
      '&Iuml;'    => 'Ï',
      '&ETH;'     => 'Ð',
      '&Ntilde;'  => 'Ñ',
      '&Ograve;'  => 'Ò',
      '&Oacute;'  => 'Ó',
      '&Ocirc;'   => 'Ô',
      '&Otilde;'  => 'Õ',
      '&Ouml;'    => 'Ö',
      '&Oslash;'  => 'Ø',
      '&Ugrave;'  => 'Ù',
      '&Uacute;'  => 'Ú',
      '&Ucirc;'   => 'Û',
      '&Uuml;'    => 'Ü',
      '&Yacute;'  => 'Ý',
      '&THORN;'   => 'Þ',
      '&szlig;'   => 'ß',
      '&agrave;'  => 'à',
      '&aacute;'  => 'á',
      '&acirc;'   => 'â',
      '&atilde;'  => 'ã',
      '&auml;'    => 'ä',
      '&aring;'   => 'å',
      '&aelig;'   => 'æ',
      '&ccedil;'  => 'ç',
      '&egrave;'  => 'è',
      '&eacute;'  => 'é',
      '&ecirc;'   => 'ê',
      '&euml;'    => 'ë',
      '&igrave;'  => 'ì',
      '&iacute;'  => 'í',
      '&icirc;'   => 'î',
      '&iuml;'    => 'ï',
      '&eth;'     => 'ð',
      '&ntilde;'  => 'ñ',
      '&ograve;'  => 'ò',
      '&oacute;'  => 'ó',
      '&ocirc;'   => 'ô',
      '&otilde;'  => 'õ',
      '&ouml;'    => 'ö',
      '&oslash;'  => 'ø',
      '&ugrave;'  => 'ù',
      '&uacute;'  => 'ú',
      '&ucirc;'   => 'û',
      '&uuml;'    => 'ü',
      '&yacute;'  => 'ý',
      '&thorn;'   => 'þ',
      '&yuml;'    => 'ÿ',

      # General HTML Symbols
      '&OElig;'   => 'Œ',
      '&oelig;'   => 'œ',
      '&Scaron;'  => 'Š',
      '&scaron;'  => 'š',
      '&Yuml;'    => 'Ÿ',
      '&fnof;'    => 'ƒ',
      '&circ;'    => 'ˆ',
      '&tilde;'   => '˜',
      '&ensp;'    => ' ',
      '&emsp;'    => ' ',
      '&thinsp;'  => ' ',
      '&zwnj;'    => '',
      '&zwj;'     => '',
      '&lrm;'     => '',
      '&rlm;'     => '',
      '&ndash;'   => '–',
      '&mdash;'   => '—',
      '&lsquo;'   => "\u2018",
      '&rsquo;'   => "\u2019",
      '&sbquo;'   => '‚',
      '&ldquo;'   => '"',
      '&rdquo;'   => '"',
      '&bdquo;'   => '„',
      '&dagger;'  => '†',
      '&Dagger;'  => '‡',
      '&bull;'    => '•',
      '&hellip;'  => '…',
      '&permil;'  => '‰',
      '&prime;'   => '′',
      '&Prime;'   => '″',
      '&lsaquo;'  => '‹',
      '&rsaquo;'  => '›',
      '&oline;'   => '‾',
      '&euro;'    => '€',
      '&trade;'   => '™',
      '&larr;'    => '←',
      '&uarr;'    => '↑',
      '&rarr;'    => '→',
      '&darr;'    => '↓',
      '&harr;'    => '↔',
      '&crarr;'   => '↵',
      '&lceil;'   => '⌈',
      '&rceil;'   => '⌉',
      '&lfloor;'  => '⌊',
      '&rfloor;'  => '⌋',
      '&loz;'     => '◊',
      '&spades;'  => '♠',
      '&clubs;'   => '♣',
      '&hearts;'  => '♥',
      '&diams;'   => '♦',

      # Mathematical Symbols
      '&forall;'  => '∀',
      '&part;'    => '∂',
      '&exist;'   => '∃',
      '&empty;'   => '∅',
      '&nabla;'   => '∇',
      '&isin;'    => '∈',
      '&notin;'   => '∉',
      '&ni;'      => '∋',
      '&prod;'    => '∏',
      '&sum;'     => '∑',
      '&minus;'   => '−',
      '&lowast;'  => '∗',
      '&radic;'   => '√',
      '&prop;'    => '∝',
      '&infin;'   => '∞',
      '&ang;'     => '∠',
      '&and;'     => '∧',
      '&or;'      => '∨',
      '&cap;'     => '∩',
      '&cup;'     => '∪',
      '&int;'     => '∫',
      '&there4;'  => '∴',
      '&sim;'     => '∼',
      '&cong;'    => '≅',
      '&asymp;'   => '≈',
      '&ne;'      => '≠',
      '&equiv;'   => '≡',
      '&le;'      => '≤',
      '&ge;'      => '≥',
      '&sub;'     => '⊂',
      '&sup;'     => '⊃',
      '&nsub;'    => '⊄',
      '&sube;'    => '⊆',
      '&supe;'    => '⊇',
      '&oplus;'   => '⊕',
      '&otimes;'  => '⊗',
      '&perp;'    => '⊥',
      '&sdot;'    => '⋅',

      # Greek Characters
      '&Alpha;'   => 'Α',
      '&Beta;'    => 'Β',
      '&Gamma;'   => 'Γ',
      '&Delta;'   => 'Δ',
      '&Epsilon;' => 'Ε',
      '&Zeta;'    => 'Ζ',
      '&Eta;'     => 'Η',
      '&Theta;'   => 'Θ',
      '&Iota;'    => 'Ι',
      '&Kappa;'   => 'Κ',
      '&Lambda;'  => 'Λ',
      '&Mu;'      => 'Μ',
      '&Nu;'      => 'Ν',
      '&Xi;'      => 'Ξ',
      '&Omicron;' => 'Ο',
      '&Pi;'      => 'Π',
      '&Rho;'     => 'Ρ',
      '&Sigma;'   => 'Σ',
      '&Tau;'     => 'Τ',
      '&Upsilon;' => 'Υ',
      '&Phi;'     => 'Φ',
      '&Chi;'     => 'Χ',
      '&Psi;'     => 'Ψ',
      '&Omega;'   => 'Ω',
      '&alpha;'   => 'α',
      '&beta;'    => 'β',
      '&gamma;'   => 'γ',
      '&delta;'   => 'δ',
      '&epsilon;' => 'ε',
      '&zeta;'    => 'ζ',
      '&eta;'     => 'η',
      '&theta;'   => 'θ',
      '&iota;'    => 'ι',
      '&kappa;'   => 'κ',
      '&lambda;'  => 'λ',
      '&mu;'      => 'μ',
      '&nu;'      => 'ν',
      '&xi;'      => 'ξ',
      '&omicron;' => 'ο',
      '&pi;'      => 'π',
      '&rho;'     => 'ρ',
      '&sigmaf;'  => 'ς',
      '&sigma;'   => 'σ',
      '&tau;'     => 'τ',
      '&upsilon;' => 'υ',
      '&phi;'     => 'φ',
      '&chi;'     => 'χ',
      '&psi;'     => 'ψ',
      '&omega;'   => 'ω',
      '&thetasym;' => 'ϑ',
      '&upsih;'   => 'ϒ',
      '&piv;'     => 'ϖ',
    }

    SPECIAL_HTML_CHARACTERS_REGEX = /&[a-zA-Z]+[0-9]*;/

    def initialize(include_links=true)
      @parsed_text = ''
      @discard = false
      @current_element = ''
      @include_links = include_links

      @current_list_index = -1
      @lists = []


      @table_columns = 0
      @parsing_link = false
      @link_text = ""
      @link_href = ""
      @parsing_bolds_and_italics = []

    end

    def convert_special_characters(text)

      special_characters = text.scan(SPECIAL_HTML_CHARACTERS_REGEX).uniq

      if special_characters.any?
        special_characters.each do |special_character|
          if HTML_SPECIAL_CHARACTERS.key?(special_character)
            text.gsub!(special_character, HTML_SPECIAL_CHARACTERS[special_character])
          elsif HTML_SPECIAL_ESCAPED_CHARACTERS.key?(special_character)
            text.gsub!(special_character, "\\#{HTML_SPECIAL_ESCAPED_CHARACTERS[special_character]}")
          end
        end
      end

      text
    end

    def add_to_parsed_text(text)
      if @parsing_link
        @link_text << text
      else
        @parsed_text << convert_special_characters(text)
      end
    end

    def start_element(name)

      if name == :b || name == :strong
        add_to_parsed_text("**")
        @parsing_bolds_and_italics << :b
      elsif name == :i || name == :em
        add_to_parsed_text("*")
        @parsing_bolds_and_italics << :i
      end

      if name == :script || name == :style || name == :head || name == :meta || name == :title
        @discard = true
      else
        @discard = false
      end

      @current_element = name

      if name== :hr
        add_to_parsed_text("\n-------------------------------------------------------------------------------------------------------------------------------------------------\n")
      end
      if name == :ul || name == :ol
        add_to_parsed_text("\n")
        @lists << {
          list_type: name,
          ordered_list_level: 1,
          ordered_list_type: "1", #If its an unordered list, this is not used. 
        }
      end

      if name.match(/h[1-6]/)
        heading_number = name.to_s[1].to_i
        add_to_parsed_text(("#" * heading_number) + " ")
      end

      if name == :a && @include_links
        @parsing_link = true
        @link_text = ""
        @link_href = ""
      end
    end

    def end_element(name)
      @discard = false

      if name == :p || name == :div || name.match(/h[1-6]/) || name == :br || name == :hr || name == :table || name == :tr
        add_to_parsed_text("\n")
      end

      if name == :a && @include_links
        @parsing_link = false

        if @link_text.present? && @link_href.present?
          add_to_parsed_text("[#{@link_text}](#{@link_href})")
        elsif @link_href.present?
          add_to_parsed_text("<#{@link_href}>")
        elsif @link_text.present?
          add_to_parsed_text(@link_text)
        end
        @link_text = ""
        @link_href = ""
      end

      if name == :li
        add_to_parsed_text("\n")
        if @lists.last.present? && @lists.last[:list_type] == :ol
          @lists.last[:ordered_list_level] += 1
        end
      end

      if name == :ul || name == :ol
        @lists.pop
      end

      if name == :b || name == :strong
        #Find the first non space character backwards to check if the bold markers are empty or not.
        last_non_space_index = @parsed_text.rindex(/\S/)
        if last_non_space_index && last_non_space_index > 2 && @parsed_text[(last_non_space_index - 1)..last_non_space_index] == "**"
          # Remove the empty bold markers from the parsed text.
          @parsed_text = @parsed_text[0..(last_non_space_index - 2)]
        else
          #if last char is a space, we move the closing bold marker before the space to avoid having markdown syntax separated by spaces, 
          #which can cause issues in some markdown renderers. Same for italics.
          if @parsed_text[-1] == " "
            @parsed_text.rstrip!
            add_to_parsed_text("**")
            @parsed_text << " "
          else
            add_to_parsed_text("**")
          end
        end

      elsif name == :i || name == :em
        #Find the first non space character backwards to check if the italic markers are empty
        last_non_space_index = @parsed_text.rindex(/\S/)
        if last_non_space_index && last_non_space_index > 2 && @parsed_text[last_non_space_index] == "*"
          # Remove the empty italic markers from the parsed text.
          @parsed_text = @parsed_text[0..(last_non_space_index - 1)]
        else
          if @parsed_text[-1] == " "
            @parsed_text.rstrip!
            add_to_parsed_text("*")
            @parsed_text << " "
          else
            add_to_parsed_text("*")
          end
        end
      end
    end

    def attr(name, value)
      if (@include_links && @current_element == :a && name == :href)
        @link_href << "#{value}"
      end

      if (@current_element == :div && name == :style && value.match?(/border-\w*:\s*solid/))
        add_to_parsed_text("\n-------------------------------------------------------------------------------------------------------------------------------------------------\n")
      end

      if (@current_element == :ol && name == :start && @lists.last.present?)
        @lists.last[:ordered_list_level] = value.to_i
      end
      if (@current_element == :ol && name == :type && @lists.last.present?)
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
          add_to_parsed_text(" " * 2 * (@lists.size - 1))
        end

        if current_list[:list_type] == :ol
          if current_list[:ordered_list_type] == "A"
            add_to_parsed_text("#{('A'.ord + current_list[:ordered_list_level] - 1).chr}. ")
          elsif current_list[:ordered_list_type] == "a"
            add_to_parsed_text("#{('a'.ord + current_list[:ordered_list_level] - 1).chr}. ")
          elsif current_list[:ordered_list_type] == "I"
            add_to_parsed_text("#{roman_numeral(current_list[:ordered_list_level])}. ")
          elsif current_list[:ordered_list_type] == "i"
            add_to_parsed_text("#{roman_numeral(current_list[:ordered_list_level]).downcase}. ")
          else
            add_to_parsed_text("#{current_list[:ordered_list_level]}. ")
          end
        else
          add_to_parsed_text("* ")
        end
      end

    end

    def text(value)

      unless value.blank? || @discard
        if value.include?("-----------------------------")
          add_to_parsed_text("\n-------------------------------------------------------------------------------------------------------------------------------------------------\n")
        else
          add_to_parsed_text("#{value}")
        end
      end
    end

    def postprocess
      
      # remove linefeeds (\r\n and \r -> \n)
      @parsed_text.gsub!(/\r\n?/, "\n")

      # strip extra spaces
      @parsed_text.gsub!(/[ \t]*\302\240+[ \t]*/, " ") # non-breaking spaces -> spaces
      @parsed_text.gsub!(/\n[\t]+/, "\n") # space at start of lines
      @parsed_text.gsub!(/[ \t]+\n/, "\n") # space at end of lines

      # no more than two consecutive newlines
      @parsed_text.gsub!(/[\n]{3,}/, "\n\n")

      @parsed_text.strip
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