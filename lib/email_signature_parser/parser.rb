# encoding: utf-8

module EmailSignatureParser

  class Parser

    SOCIAL_MEDIA_URLS = ['instagram', 'twitter', 'facebook', 'linkedin', 'youtube', 'tiktok', 'bsky']

    PHONES_TO_COUNTRY = {"1"=>"US/CA", "7"=>"KZ", "20"=>"EG",  "27"=>"ZA",  "30"=>"GR",  "31"=>"NL",  "32"=>"BE",  "33"=>"FR",  "34"=>"ES",  "36"=>"HU", "39"=>"IT",
      "40"=>"RO", "41"=>"CH", "43"=>"AT", "44"=>"GB", "45"=>"DK", "46"=>"SE", "47"=>"NO", "48"=>"PL", "49"=>"DE", "51"=>"PE", "52"=>"MX", "53"=>"CU",
      "54"=>"AR", "55"=>"BR", "56"=>"CL", "57"=>"CO", "58"=>"VE", "60"=>"MY", "61"=>"AU", "62"=>"ID", "63"=>"PH", "64"=>"NZ", "65"=>"SG", "66"=>"TH", "81"=>"JP",
      "82"=>"KR", "84"=>"VN", "86"=>"CN", "90"=>"TR", "91"=>"IN", "92"=>"PK", "93"=>"AF", "94"=>"LK", "95"=>"MM", "98"=>"IR", "211"=>"SS", "212"=>"MA", "213"=>"DZ",
      "216"=>"TN", "218"=>"LY", "220"=>"GM", "221"=>"SN", "222"=>"MR", "223"=>"ML", "224"=>"GN", "225"=>"CI", "226"=>"BF", "227"=>"NE", "228"=>"TG", "229"=>"BJ", "230"=>"MU",
      "231"=>"LR", "232"=>"SL", "233"=>"GH", "234"=>"NG", "235"=>"TD", "236"=>"CF", "237"=>"CM", "238"=>"CV", "239"=>"ST", "240"=>"GQ", "241"=>"GA", "242"=>"CG", "243"=>"CD",
      "244"=>"AO", "245"=>"GW", "246"=>"IO", "248"=>"SC", "249"=>"SD", "250"=>"RW", "251"=>"ET", "252"=>"SO", "253"=>"DJ", "254"=>"KE", "255"=>"TZ", "256"=>"UG", "257"=>"BI",
      "258"=>"MZ", "260"=>"ZM", "261"=>"MG", "262"=>"YT", "263"=>"ZW", "264"=>"NA", "265"=>"MW", "266"=>"LS", "267"=>"BW", "268"=>"SZ", "269"=>"KM", "290"=>"SH", "291"=>"ER",
      "297"=>"AW", "298"=>"FO", "299"=>"GL", "350"=>"GI", "351"=>"PT", "352"=>"LU", "353"=>"IE", "354"=>"IS", "355"=>"AL", "356"=>"MT", "357"=>"CY", "358"=>"FI", "359"=>"BG",
      "370"=>"LT", "371"=>"LV", "372"=>"EE", "373"=>"MD", "374"=>"AM", "375"=>"BY", "376"=>"AD", "377"=>"MC", "378"=>"SM", "379"=>"VA", "380"=>"UA", "381"=>"RS", "382"=>"ME",
      "385"=>"HR", "386"=>"SI", "387"=>"BA", "389"=>"MK", "420"=>"CZ", "421"=>"SK", "423"=>"LI", "500"=>"FK", "501"=>"BZ", "502"=>"GT", "503"=>"SV", "504"=>"HN", "505"=>"NI",
      "506"=>"CR", "507"=>"PA", "508"=>"PM", "509"=>"HT", "590"=>"MF", "591"=>"BO", "592"=>"GY", "593"=>"EC", "594"=>"GF", "595"=>"PY", "596"=>"MQ", "597"=>"SR", "598"=>"UY",
      "599"=>"SX", "670"=>"TL", "672"=>"NF", "673"=>"BN", "674"=>"NR", "675"=>"PG", "676"=>"TO", "677"=>"SB", "678"=>"VU", "679"=>"FJ", "680"=>"PW", "681"=>"WF", "682"=>"CK", "683"=>"NU",
      "685"=>"WS", "686"=>"KI", "687"=>"NC", "688"=>"TV", "689"=>"PF", "690"=>"TK", "691"=>"FM", "692"=>"MH", "850"=>"KP", "852"=>"HK", "853"=>"MO", "855"=>"KH", "856"=>"LA",
      "870"=>"PN", "880"=>"BD", "886"=>"TW", "960"=>"MV", "961"=>"LB", "962"=>"JO", "963"=>"SY", "964"=>"IQ", "965"=>"KW", "966"=>"SA", "967"=>"YE", "968"=>"OM", "970"=>"PS",
      "971"=>"AE", "972"=>"IL", "973"=>"BH", "974"=>"QA", "975"=>"BT", "976"=>"MN", "977"=>"NP", "992"=>"TJ", "993"=>"TM", "994"=>"AZ", "995"=>"GE", "996"=>"KG", "998"=>"UZ"}

    JOB_TITLES = YAML.load_file(
      File.expand_path('../../../lib/email_signature_parser/data/job_titles/titles.yaml', __FILE__), symbolize_names: true
    )
    MEETING_DOMAINS = [
      /zoom\.us/i,
      /teams\.microsoft\.com/i,
      /meet\.google\.com/i,
      /webex\.com/i,
      /gotomeeting\.com/i,
      /ringcentral\.com/i
    ]
    def initialize
      @signature_sentences = []
      @sentences = []
    end

    # Calculates the percentage of digits in a text, ignoring spaces and HTML links.
    def get_digits_percentage(text)
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
    def merge_small_strings(array)

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
            array = array[0..array.size - 2] + [last_items.join("")]
          end
        end

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

    def meeting_email?(email_body)
      MEETING_DOMAINS.any? { |regex| email_body =~ regex }
    end


    def get_signature_sentences(name, email_address, email_body)

      email_sentences = email_body.split(/\t|\n|\r/).map{|s| s.strip}

      signature_start_index = email_sentences.size
      
      first_consecutive_carriage_returns_index = -1
      consecutive_carriages_found = []

      consecutive_return_carriage = 0
      foundContent = false

      # Find the first consecutive empty lines that come after some content.
      email_sentences.each_with_index do |sentence, index|

        if !foundContent
          if sentence.split(" ").size > 2
            foundContent = true
          end
          next
        end
          
        if sentence == ""
          # empty chars are breaks 
          consecutive_return_carriage += 1
        else
          if consecutive_return_carriage >= 2
            consecutive_carriages_found << index - 1
          end
          consecutive_return_carriage = 0
        end
      end

      if consecutive_return_carriage >= 2
        consecutive_carriages_found << email_sentences.index(sentence) - 1
      end

      if consecutive_carriages_found.size == 0
        # No consecutive carriages found, assume no signature
        return
      end

      first_consecutive_carriage_returns_index = consecutive_carriages_found.first || -1

      @sentences = []

      splitted_name = []
      if name.present?
        splitted_name = merge_small_strings(name.downcase.gsub(/[^\w\s]/, ' ').gsub(/\s+/, ' ').split(" "))
      elsif email_address.present?
        # No name provided, try to extract from email address, in case email is like jdoe@email.com or john.doe@email.com
        splitted_name = merge_small_strings(email_address.split("@").first.downcase.gsub(/[^\w\s]/, ' ').gsub(/\s+/, ' ').split(" "))
      end

      signature_start_index = -1
      found_email_index = -1
      found_name_index = -1
      email_sentences.each_with_index do |sentence, index|
        @sentences << { isSignature: false , doc: nil, type: 'unknown' }
        if (sentence.include?("http") || sentence.include?("www") || index < first_consecutive_carriage_returns_index)
          # If the sentence contains an email or link, or is before the first long break, dont even bother analyzing it
          next
        end

        downcased_sentence = sentence.downcase
        sentence_words = downcased_sentence.gsub(/[^\w\s\.]/, ' ').gsub(/\s+/, ' ').split(" "
          ).filter{|w| w.size < 15}
        #Leave dots in sentence words. is to prevent splitting usernames like name.surname34
        #Remove words longer than 15 chars, as they are unlikely to be names
      
        if sentence_words.size < 8 && sentence_words.size > 0
          similarities = []
          splitted_name.each do |splitted_name_word|
            similarities << sentence_words.map {|word| word.similarity(splitted_name_word)}.max
          end
          
          sim_max = similarities.max
          if sim_max.present? && sim_max > 0.7
            signature_start_index = index
            found_name_index = index
          end
        end

        if (found_email_index == - 1 && downcased_sentence.include?(email_address))
          found_email_index = index
        end
      end

      if signature_start_index == -1
        if found_email_index == -1
          # No name or email found, assume no signature
          return
        end

        # Lets try and find the name based on the email index
        # Get closest consecutive carriage return index
        closest_consecutive_index = consecutive_carriages_found.select { |i| i < found_email_index }.max
        if (closest_consecutive_index - found_email_index).abs < 3
          signature_start_index = closest_consecutive_index + 1
        end
      end

      signature_end_index = -1

      email_sentences.each_with_index do |sentence, index|
        if index >= signature_start_index 
          sentence_no_links = sentence.gsub(/<a href(.*?)\/a>/, '')
          if (sentence_no_links.count('*') > 5 || sentence_no_links.count('-') > 5 || sentence_no_links.size >= 150)
            signature_end_index = index
            break
          end
        end
      end

      @sentences.each_with_index do |sentence, index|
        sentence[:doc] = email_sentences[index].strip
        if index == found_name_index
          sentence[:type] = 'name'
        end

        if index >= signature_start_index && (signature_end_index == -1 || index < signature_end_index)
          sentence[:isSignature] = true
          sentence[:doc] = email_sentences[index].strip
          sentence[:digits_pct] = get_digits_percentage(email_sentences[index])
        end
      end

      @signature_sentences = @sentences.filter{|s| s[:isSignature] && s[:doc].present?}
    end

    def get_address

      cityOrStateIndexes = []
      cityOrStateIndex = -1

      countryIndex = -1
      postCodeIndex = -1
      streetIndex = -1

      @signature_sentences.each_with_index do |sentence, index|
        address_parts = {
          house: 0,
          house_number: 0,
          road: 0,
          postcode: 0,
          city_district: 0,
          city: 0,
          state_district: 0,
          state: 0,
          country_region: 0,
          country: 0
        }
        

        @signature_sentences[index][:address_parts] = address_parts
        if (sentence[:digits_pct][:total] > 7 && sentence[:digits_pct][:pct] > 0.4)
          #Too many digits, assume its a phone number and not an address
          next
        end

        if (sentence[:doc].include?("@") || sentence[:doc].include?("www") || sentence[:doc].include?("http"))
          next
        end

        parsed_address = Postal::Parser.parse_address(sentence[:doc])
        @signature_sentences[index][:parsed_address] = parsed_address
        parsed_address.each do |val| 
          if address_parts[val[:label]]
            address_parts[val[:label]] += 1
          end
        end

        @signature_sentences[index][:address_parts] = address_parts
        if (index > 0 && (address_parts[:city] > 0 || address_parts[:state] > 0))
          #cityOrStateIndex = index
          cityOrStateIndexes << index
        end
        if (index > 0 && address_parts[:country] > 0 && countryIndex < 0)
          countryIndex = index
          @signature_sentences[countryIndex][:type] = 'address'
        end
        if (index > 0 && address_parts[:postcode] > 0 && postCodeIndex < 0)
          postCodeIndex = index
        end
      end


      if cityOrStateIndexes.size > 0
        if countryIndex > 0 
          cityOrStateIndex = cityOrStateIndexes.min_by{|index| (countryIndex-index).abs}
        elsif postCodeIndex > 0
          cityOrStateIndex = cityOrStateIndexes.min_by{|index| (postCodeIndex-index).abs}
        elsif cityOrStateIndexes.size > 0
          cityOrStateIndex = cityOrStateIndexes.first
        end  
      end

      @signature_sentences.each_with_index do |sentence, index|

        if (cityOrStateIndex > 0 && 
          (@signature_sentences[index][:address_parts][:road] > 0  || 
          @signature_sentences[index][:address_parts][:house] > 0 || 
          @signature_sentences[index][:address_parts][:house_number] > 0) && 
            streetIndex < 0 && (cityOrStateIndex - index).abs < 2)
          streetIndex = index
        end
      end

      if (cityOrStateIndex > 0  && (streetIndex > 0 && (cityOrStateIndex - streetIndex).abs < 2))
        @signature_sentences[cityOrStateIndex][:type] = 'address'
        @signature_sentences[streetIndex][:type] = 'address'
      end

      if (cityOrStateIndex > 0  && (countryIndex > 0 && (cityOrStateIndex - countryIndex).abs < 3))
        @signature_sentences[cityOrStateIndex][:type] = 'address'
        @signature_sentences[countryIndex][:type] = 'address'
      end

      if (cityOrStateIndex > 0  && (postCodeIndex > 0 && (cityOrStateIndex - postCodeIndex).abs < 3))
        @signature_sentences[cityOrStateIndex][:type] = 'address'
        @signature_sentences[postCodeIndex][:type] = 'address'
      end
        
      total_address_count = 0
      @signature_sentences.each do |sentence|
        if sentence[:type] == 'address'
          total_address_count += sentence[:doc].size
        end
      end
      if (total_address_count > 150)
        return ""
      end

      address_text = @signature_sentences.filter{|sentence| sentence[:type] == 'address'}.map{
        |sentence| sentence[:doc].gsub(/.*?:/, ' ').gsub(/[\|><]/, ' ')}.join(", ")


      if address_text.size > 150
        return ""
      end

      #Replace multiple commas with a single comma. or a comma preceded by a space
      address_text = address_text.gsub(/\s+/, ' ').gsub(/,+|\ ,/, ',')

      return address_text.lstrip
    end

    def get_phones
      phones = []
      @signature_sentences[1..]&.each_with_index do |sentence, index|
        if sentence[:digits_pct][:total] > 7 && sentence[:digits_pct][:pct] > 0.4
          @signature_sentences[index+1][:type] = 'phone'
          phone_texts = sentence[:doc].split(/[\|●]/)

          phone_texts.each do |phone_text|
            match_before_number = phone_text.match(/.*?:|[tpmd]\./)

            phone_type = 'Phone'
            unless match_before_number.nil?
              match_text = match_before_number[0].downcase()
              if match_text.include?('m:') || match_text.include?('mobile') || match_text.include?('movil') || 
                match_text.include?('móvil') || match_text.include?('c:') || match_text.include?('cell')
                phone_type = 'Mobile'
              elsif match_text.include?('o:') || match_text.include?('office') || match_text.include?('oficina')
                phone_type = 'Office'
              elsif match_text.include?('f:') || match_text.include?('fax:')
                phone_type = 'Fax'
              elsif match_text.include?('direct') && match_text.include?("line") || match_text.include?('d:')
                phone_type = 'Direct Line'
              end

              phone_text = phone_text.gsub(match_text, '')
            end

            if phone_text.include?("<a href")
              #Phone is inside a link. Extract only text.
              phone_text = phone_text.gsub(/<a[^>]*>|<\/a>/, '')
            end

            
            digits = phone_text.gsub(/[^\+|\d|\s\.|\(|\)]/, '').gsub(/(\+\s+\+)|(\++)/, '+').gsub(/\s+/, ' ').strip
            
            if digits.gsub(/[^\d]/, '').size > 15
              # Too long to be a phone number, skip
              next
            end

            begin
              parsed_number = Phoner::Phone.parse(digits)
              phones << {
                type: phone_type,
                phone_number: parsed_number.format(:europe),
                country: PHONES_TO_COUNTRY[parsed_number.country_code]
              }
            rescue Exception => e
              phones << {
                type: phone_type,
                phone_number: digits, #remove multiple + signs.
                country: ''
              }
            end
          end
        end
      end

      return phones

    end

    def get_links()
      
      parsed_links = {
        social_media: {},
        other: []
      }

      @signature_sentences[1..]&.each_with_index do |sentence, index|
        links_in_sentence = sentence[:doc].scan(/(?<=(href=")).*?(?=")/).map {$&}
        for link in links_in_sentence
          if link.include?('mailto:')
            sentence[:type] = 'mailto'
          else
            sentence[:type] = 'link'
            isSocialMedia = false
            SOCIAL_MEDIA_URLS.each do |social_media|
              if link.include?(social_media)
                parsed_links[:social_media][social_media] = link.include?("http") ? link : "https://#{link}"
                isSocialMedia = true
                break
              end
            end
            if !isSocialMedia
              olink = link.include?("http") ? link : "https://#{link}"
              parsed_links[:other] << olink
            end
          end
        end
      end

      return parsed_links
    end

    def get_company_name(email_address)
      
      company_name = []
      emailAtIndex = email_address.index("@")
      if emailAtIndex.nil?
        return ''
      end
      
      company_domain = PublicSuffix.parse(email_address[(emailAtIndex+1)..]).sld
      min_sim = 0.5

      @signature_sentences[1..3]&.each do |sentence|
        text = sentence[:doc].strip()
        if text.include?("@") || text.include?("www") || text.include?("http")
          next
        end
        splitted_text = text.split(" ")
        splitted_text.each do |word|
          sim = word.downcase.similarity(company_domain)
          if (sim >= min_sim)
            if (splitted_text.size <= 3)
              company_name = splitted_text
              break
            else
              company_name << word.strip()
            end
          end
        end
      end

      return company_name.uniq.join(" ")
          
    end

    def get_job_title()

      job_title = ''
      acronyms_found = []
      @signature_sentences[0..1]&.each_with_index do |sentence, index|
      
        if sentence[:doc].include?("@") || sentence[:doc].include?("www") || sentence[:doc].include?("http")
          next
        end

        found = 0
        clean_sentence = sentence[:doc].gsub(/[^\w\s]/, ' ').gsub(/\s+/, ' ').strip
        splitted_downcased_words = clean_sentence.downcase.split(' ')

        found += (splitted_downcased_words & JOB_TITLES[:titles]).size

        acronyms_found += (splitted_downcased_words & JOB_TITLES[:acronyms]).map(&:upcase)
        acronyms_found += (splitted_downcased_words & JOB_TITLES[:single_titles]).map(&:capitalize)

        if found >= 2
          job_title = sentence[:doc]
        end
      end

      return {
        title: job_title,
        acronym: acronyms_found.join(", ")
      }
    end

    def parse_signature(name, email_address, email_body)

      @signature_sentences = []
      @sentences = []

      get_signature_sentences(name, email_address, email_body)

      address = get_address()
      phones = get_phones()
      links = get_links()
      job_title = get_job_title()

      parsed_name = name

      if parsed_name.blank?
        # Try to extract name from the first two sentences of the signature
        @signature_sentences[0..1].filter{|s| s[:type] == 'unknown'}.each do |sentence|
          sentence_words = sentence[:doc].split(" ")
          if sentence_words.size > 1 && sentence_words.size < 4 && sentence_words.reduce(true){|acc, val| val.size < 15 && acc}
            parsed_name = sentence_words.map{|n| n.capitalize}.join(" ")
          end
        end
      end


      parsed_data = {
        name: parsed_name,
        email_address: email_address,
        address: address,
        phones: phones,
        links: links,
        job_title: job_title,
        text: @signature_sentences.map{|sentence| sentence[:doc]}.join("\n"),
        company_name: get_company_name(email_address)
      }

      @signature_sentences = []
      @sentences = []

      return parsed_data
    end

    def split_in_threads(text)

      # Regex for reply markers. Handles English and Spanish.
      marker_regex = /(De:\s.+@+.+)|(From:\s.+@+.+)/i

      marker_indexes = text.enum_for(:scan, marker_regex).map { Regexp.last_match.begin(0) }
      messages = []
      last_index = 0

      marker_indexes.each do |marker_index|
        messages << text[last_index...marker_index].strip
        last_index = marker_index
      end

      if last_index < text.size
        messages << text[last_index..].strip
      end

      return messages
    end

    def parse_email_html(raw_html)
      content = raw_html[/<html.*<\/html>/m]

      # Gets only the html part of the email
      if content.nil?
        raise "No HTML content found"
      end

      options = {
        symbolize: true,
        skip: :skip_white,
        smart: true,
        mode:   :generic,
        effort: :tolerant,
      }
      input = StringIO.new(content)
      text_handler = HtmlTextParser.new()
 
      Ox.sax_html(text_handler, input, options)
      text_handler.postprocess

      return text_handler.parsed_text
    end

    def extract_name_and_email(from)
      name = ""
      email_address = ""

      if from.include?("<") && from.include?(">")
        # From likely to include name and email address Name <email@example.com>
        name = from.split("<").first.strip
        email_address = from.match(/<(.+?)>/)&.captures&.first || ""
      else
        email_address = from.strip
      end

      splitted_name = name.split(" ")
      if splitted_name.any?{|n| n.size > 15}
        # Name likely to be invalid, as it contains very long words
        # There are sometimes funny names in the from header, like: "=?utf-8?B?TWlrZSBCcm93bmxlYWRlciBlbiBUZWFtcw==?=" <noreply@emeaemail.teams.microsoft.com>
        name = ""
      end

      return name, email_address.downcase
    end

    def parse_from_file(file_path)

      m = Mail.read(file_path)

      html_part = ""
      text_part = m.text_part ? m.text_part.decode_body : ""
      encoding = nil
      if m.html_part.present? 
        
        if m.html_part.content_type_parameters && m.html_part.content_type_parameters['charset'].present?
          encoding = m.html_part.content_type_parameters['charset']
        elsif m.html_part.charset.present?
          encoding = m.html_part.charset
        end
          
        if encoding.present?
          html_part = m.html_part.decode_body.force_encoding(encoding)
        else
          html_part = m.html_part.decode_body.force_encoding('UTF-8')
        end
        html_part = html_part.encode('UTF-8')
      else
        # First attempt to get encoding from the raw source, mail gem does not correctly recognize the charset sometimes
        encoding = m.raw_source[/charset="([^"]+)"/, 1]
        unless encoding.present?
          if m.content_type_parameters && m.content_type_parameters['charset'].present?
            encoding = m.content_type_parameters['charset']
          elsif m.charset.present?
            encoding = m.charset
          end
        end

        if encoding.present?
          html_part = m.decode_body.force_encoding(encoding)
        else
          html_part = m.decode_body.force_encoding('UTF-8')
        end

        html_part = html_part.encode('UTF-8')

      end

      from = m.header["From"]&.field&.value
      unless from.present?
        raise "No From field in email"
      end

      name, email_address = extract_name_and_email(from)

      if html_part.present?
        if meeting_email?(m.body.decoded)
          raise "Meeting email detected, no signature to parse"
        end

        text_part = parse_email_html(html_part)
      end
      unless text_part.present?
        raise "No email body"
      end

     # basename = File.basename(file_path)
     # File.write("test_output_#{basename}.txt", text_part)

      messages = split_in_threads(text_part)

      # Only parse the first message in the thread, as its the most recent one and the one sent by the from address
      parse_signature(name, email_address.downcase, messages.first)
    end

    def parse_from_html(from, email_html_body)
      unless from.present?
        raise "No from provided"
      end

      unless email_html_body.present?
        raise "No email body provided"
      end

      name, email_address = extract_name_and_email(from)
      parsed_text = parse_email_html(email_html_body)
      messages = split_in_threads(parsed_text)

      parse_signature(name, email_address.downcase, messages.first)
    end

    def parse_from_text(from, email_body)
      unless from.present?
        raise "No from provided"
      end

      name, email_address = extract_name_and_email(from)
      messages = split_in_threads(email_body)

      parse_signature(name, email_address.downcase, messages.first)
    end
  end
end
