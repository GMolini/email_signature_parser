# encoding: utf-8

module EmailSignatureParser

  class ParseError < StandardError; end
  class InvalidEmailError < ParseError; end
  class InvalidFromError < ParseError; end

  class Parser

    SOCIAL_MEDIA_URLS = ['instagram', 'x', 'twitter', 'facebook', 'linkedin', 'youtube', 'tiktok', 'bsky']

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
    ) + YAML.load_file(
      File.expand_path('../../../lib/email_signature_parser/data/job_titles/titles_es.yaml', __FILE__), symbolize_names: true
    )

    JOB_ACRONYMS = YAML.load_file(
      File.expand_path('../../../lib/email_signature_parser/data/job_titles/acronyms.yaml', __FILE__), symbolize_names: true
    ) 

    MEETING_DOMAINS = [
      /zoom\./i,
      /teams\.microsoft\.com/i,
      /meet\.google\.com/i,
      /webex\.com/i,
      /gotomeeting\.com/i,
      /ringcentral\.com/i
    ]

    COMMON_EMAIL_DOMAINS = [
      'gmail.com', 
      'yahoo.', # includes yahoo.com, yahoo.co.uk, etc
      'hotmail.', # includes hotmail.com, hotmail.co.uk, etc
      'outlook.com', 
      'aol.com', 
      'icloud.com', 
      'mail.com', 
      'gmx.', 
      'protonmail.com', 
      'zoho.com'
    ]

    COMMON_COMPANY_ENDINGS = [
      # English suffixes
      'inc', 'incorporated', 'corp', 'corporation', 'company', 'co', 'ltd', 'limited', 
      'llc', 'lp', 'partnership', 'plc', 'public',
      'enterprises', 'group', 'holdings', 'international', 'intl', 'worldwide',
      'global', 'associates', 'partners', 'consulting', 'services', 'solutions',
      'systems', 'technologies', 'tech', 'industries', 'manufacturing', 'mfg',
      
      # Spanish suffixes
      'sa', 'sociedad', 'anónima', 'sl', 'srl', 'responsabilidad', 'limitada',
      'sc', 'scp', 'colectiva', 'civil', 'particular', 'scpp', 'público', 'privada',
      'sad', 'deportiva', 'sal', 'laboral', 'sll',
      'sau', 'unipersonal', 'slu', 'compañía', 'cia', 'empresa', 'corporación', 'grupo', 'holding',
      'internacional', 'mundial', 'global', 'asociados', 'socios', 'consultoría',
      'servicios', 'soluciones', 'sistemas', 'tecnologías', 'industrias', 'industrial',
      'ltda', 'limitada',
      # International/European suffixes (commonly used in Spanish-speaking countries)
      'gmbh', 'ag', 'bv', 'nv', 'oy', 'ab', 'sas', 'spa', 'pte', 'kg', 'kgaa',
    ]

    MAX_SIGNATURE_LINES = 12
    MAX_SENTENCE_LENGTH = 150
    MAX_NAME_WORD_LENGTH = 15
    MIN_PHONE_DIGITS = 8
    MAX_PHONE_DIGITS = 15
    COMPANY_NAME_SIMILARITY_THRESHOLD = 0.6
    NAME_SIMILARITY_THRESHOLD = 0.7


    def initialize
      @signature_sentences = []
      @parsed_name_from_signature = ''
    end

    def meeting_email?(email_body)
      MEETING_DOMAINS.any? { |regex| email_body =~ regex }
    end

    def get_signature_sentences(name, email_address, email_body)

      if email_body.nil? || email_body.empty?
        raise InvalidEmailError, "No email body provided"
      end

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
          
        if sentence == "" || sentence.count('*') > 5 || sentence.count('-') > 5 || sentence.count('_') > 5
          # empty chars are breaks 
          consecutive_return_carriage += 1
        else
          if consecutive_return_carriage >= 1
            consecutive_carriages_found << index - 1
          end
          consecutive_return_carriage = 0
        end
      end

      if consecutive_carriages_found.size == 0
        # No consecutive carriages or separators found, assume no signature
        return
      end

      first_consecutive_carriage_returns_index = consecutive_carriages_found.first || -1

      sentences = []

      splitted_name = []
      email_prefix = ""
      if !name.empty?
        splitted_name = name.downcase.gsub(/[^\w\s]/, ' ').gsub(/\s+/, ' ').split(" ")
      elsif !email_address.empty?
        email_prefix = email_address.split("@").first.downcase
      end

      signature_start_index = -1
      found_email_index = -1
      found_name_index = -1
      email_sentences.each_with_index do |sentence, index|
        sentences << { isSignature: false , doc: nil, type: 'unknown' }
        if (sentence.include?("http") || sentence.include?("www") || index < first_consecutive_carriage_returns_index)
          # If the sentence contains an email or link, or is before the first long break, dont even bother analyzing it
          next
        end

        downcased_sentence = sentence.downcase
        sentence_words = downcased_sentence.gsub(/[^\w\s\.\@]/, ' ').gsub(/\s+/, ' ').split(" ")
        #Leave dots in sentence words. is to prevent splitting usernames like name.surname34
        #Remove words longer than 15 chars, as they are unlikely to be names
      
        if sentence_words.size < 8 && sentence_words.size > 0
          similarities = []

          #Discard long words (cant be a name) and words with digits
          filtered_words = sentence_words.filter{|w| w.size < MAX_NAME_WORD_LENGTH && !w.match?(/\d/)}

          splitted_name.each do |splitted_name_word|
            similarities << filtered_words.map {|word| word.similarity(splitted_name_word)}.max
          end
          sim_max = similarities.max || 0

          if sim_max < NAME_SIMILARITY_THRESHOLD && !email_prefix.empty?
            # We are trying to see if a combination of the words in the sentence can match the email prefix

            # Also consider common patterns in emails to match names
            #Common email patterns
            # {first}@company
            # {first}{last}@company
            # {first}.{last}@company
            # {f}{last}@company
            # {f}.{last}@company
            # {first}{middle}{last}@company
            # {first}.{middle}.{last}@company
            # {f}.{middle}.{last}@company
            # {f}{m}{last}@company
            filtered_words.each_with_index do |word, wIndex|
              #If the word starts with same letter as the searched email, build the possible names
              wordsUntilEnd = filtered_words[(wIndex+1)..]

              if word[0] == email_prefix[0] && wordsUntilEnd.size > 0
                
                possible_first_last_emails = [
                  word, #first@company
                  word + wordsUntilEnd.first, #firstlast@company
                  word + "." + wordsUntilEnd.first, #first.last@company
                  word[0] + wordsUntilEnd.first, #flast@company
                  word[0] + "." + wordsUntilEnd.first, #f.last@company
                ]

                possible_first_last_emails.each do |possible_email|
                  if possible_email == email_prefix
                    sim_max = 1.0
                    @parsed_name_from_signature = word.capitalize + " " + wordsUntilEnd.first.capitalize
                    break
                  end
                end

                if wordsUntilEnd.size > 1
                  possible_first_middle_last_emails = [
                    # We may be in a situation where theres a middle name but not used in the email
                    word, #first@company
                    word + wordsUntilEnd[1], #firstlast@company
                    word + "." + wordsUntilEnd[1], #first.last@company
                    word[0] + wordsUntilEnd[1], #flast@company
                    word[0] + "." + wordsUntilEnd[1], #f.last@company

                    word + wordsUntilEnd.first + wordsUntilEnd[1], #firstmiddlelast@company
                    word + "." + wordsUntilEnd.first + "." + wordsUntilEnd[1], #first.middle.last@company
                    word[0] + "." + wordsUntilEnd.first + "." + wordsUntilEnd[1], #f.middle.last@company
                    word[0] + wordsUntilEnd.first[0] + wordsUntilEnd[1] #fmlast@company
                  ]

                  possible_first_middle_last_emails.each do |possible_email|
                    if possible_email == email_prefix
                      sim_max = 1.0
                      @parsed_name_from_signature = word.capitalize + " " + wordsUntilEnd.first.capitalize + " " + wordsUntilEnd[1].capitalize
                      break
                    end
                  end
                end
              end
            end
          end

          if sim_max > NAME_SIMILARITY_THRESHOLD
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
        if (closest_consecutive_index - found_email_index).abs < 8
          signature_start_index = closest_consecutive_index + 1
        end
      end

      signature_end_index = -1

      email_sentences.each_with_index do |sentence, index|
        if index >= signature_start_index 
          sentence_no_links = sentence.gsub(/<a href(.*?)\/a>/, '')
          if (sentence_no_links.count('*') > 5 || sentence_no_links.count('-') > 5 || sentence_no_links.size >= MAX_SENTENCE_LENGTH) ||
            (sentence == "" && email_sentences[index+1] == "") # If big break, assume end of signature
            signature_end_index = index
            break
          end
        end
      end

      sentences.each_with_index do |sentence, index|
        sentence[:doc] = email_sentences[index].strip
        if index == found_name_index
          sentence[:type] = 'name'
        end

        if index >= signature_start_index && (signature_end_index == -1 || index < signature_end_index)
          sentence[:isSignature] = true
          sentence[:doc] = email_sentences[index].strip
        end
      end

      @signature_sentences = sentences.filter{|s| s[:isSignature] && !s[:doc].nil? && !s[:doc].empty?}
      if @signature_sentences.size > MAX_SIGNATURE_LINES
        # Unlikely to be a signature if it has more than 12 lines
        @signature_sentences = []
      end
    end

    def get_address
      cityOrStateIndexes = []
      postCodeIndexes = []
      countryIndex = -1
      streetIndexes = []

      @signature_sentences.each_with_index do |sentence, index|
        if sentence[:type] != 'unknown'
          next
        end

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

        # remove links from the sentence before parsing
        possible_address = sentence[:doc].gsub(/<a href(.*?)\/a>/, '')
        parsed_address = Postal::Parser.parse_address(possible_address)

        parsed_address.each do |val| 
          if address_parts[val[:label]]
            address_parts[val[:label]] += 1
          end
        end

        if max_consecutive_digits = Utils.max_consecutive_digits(possible_address) > 9 && 
          (!address_parts[:country].positive? || !address_parts[:state].positive?)
          # looks like a number, not part of address, discard
          next
        end

        if (index > 0 && (address_parts[:city] > 0 || address_parts[:state] > 0))
          cityOrStateIndexes << index
        end
        if (index > 0 && address_parts[:country] > 0 && countryIndex < 0)
          countryIndex = index
          @signature_sentences[countryIndex][:type] = 'address'
        end
        if (index > 0 && address_parts[:postcode] > 0)
          postCodeIndexes << index
        end

        if (address_parts[:road] > 0  && address_parts[:house] > 0) || 
          (address_parts[:road] > 0 && address_parts[:house_number] > 0) ||
          (address_parts[:house] > 0 && address_parts[:house_number] > 0)
          streetIndexes << index
        end
      end

      cityOrStateIndexes.each do |cityIndex|
        streetIndexes.each do |streetIndex|
          if ((cityIndex - streetIndex).abs < 2)
            @signature_sentences[cityIndex][:type] = 'address'
            @signature_sentences[streetIndex][:type] = 'address'
          end
        end
        if (countryIndex > 0 && (cityIndex - countryIndex).abs < 3)
          @signature_sentences[cityIndex][:type] = 'address'
        end
        postCodeIndexes.each do |postCodeIndex|
          if ((cityIndex - postCodeIndex).abs < 3)
            @signature_sentences[cityIndex][:type] = 'address'
            @signature_sentences[postCodeIndex][:type] = 'address'
          end
        end
      end

      address_text = @signature_sentences.filter{|sentence| sentence[:type] == 'address'}.map{
        |sentence| sentence[:doc].gsub(/<a href(.*?)\/a>/, '').gsub(/.*?:/, ' ').gsub(/[\|><]/, ' ')}.join(", ")

      if address_text.size > MAX_SENTENCE_LENGTH
        @signature_sentences.filter{|s| s[:type] == 'address'}.each{|s| s[:type] = 'unknown'}
        return ""
      end

      #Replace multiple commas with a single comma. or a comma preceded by a space
      address_text = address_text.gsub(/\s+/, ' ').gsub(/,+|\ ,/, ',')

      return address_text.strip
    end

    def get_phones
      phones = []
      @signature_sentences[1..]&.each_with_index do |sentence, index|
        
        #Sometimes multiple phones are in the same line separated by | or ●
        #They can also be in the same line as Telephone 1123123 Mobile 123123123
        text = sentence[:doc].gsub(/<a href(.*?)\/a>/, '')

        phone_texts = text.scan(/(.*?\+?\d+(?:[\s\-\(\)\.]+\d+)*(?:\s*(?:\([^)]+\)|[A-Za-z][^,\n]*))?)|[\|●\,]/
        ).flatten.reject(&:nil?).map{|pt| pt.gsub(/[\|●\,]/, '').strip}.reject(&:empty?)

        phone_texts.each do |phone_text|
          # See if phone text is an extension
          # common patterns: ext. 1234, x1234, x.1234, ext1234
          extension_regex = /\b(ext\.?|extension)[\.\:\s]*\d+|(?<!\w)x[\.\:\s]*\d+/i
          extension_match = phone_text.match(extension_regex)
          extension = nil
          if extension_match
            extension = extension_match[0].gsub(/[^\d]/, '').strip
            phone_text = phone_text.gsub(extension_regex, '').strip
          end

          max_consecutive_digits = Utils.max_consecutive_digits(phone_text)
          if max_consecutive_digits < MIN_PHONE_DIGITS || max_consecutive_digits > MAX_PHONE_DIGITS
            # Too few or too many consecutive digits to be a phone number, skip
            if !extension.nil? && !extension.empty? && phones.size > 0
              # They wrote the number like "123-123-124, ext. 1234". Assign the extension to the last phone found
              phones.last[:extension] = extension
            end
            next
          end

          @signature_sentences[index+1][:type] = 'phone'
          match_before_number = phone_text.match(/[^\d\+\(\)]*(?=[\d\+\(])/i)
          phone_type = 'Phone'
          unless match_before_number.nil?
            match_text = match_before_number[0].downcase()
            if match_text.include?('m:') || match_text.include?('mobile') || match_text.include?('movil') || 
              match_text.include?('móvil') || match_text.include?('c:') || match_text.include?('cell')
              phone_type = 'Mobile'
            elsif match_text.include?('o:') || match_text.include?('office') || match_text.include?('oficina') ||
              match_text.include?('work') || match_text.include?('w:') || match_text.include?('trabajo')
              phone_type = 'Office'
            elsif match_text.include?('f:') || match_text.include?('fax')
              phone_type = 'Fax'
            elsif match_text.include?('direct') && match_text.include?("line") || match_text.include?('d:')
              phone_type = 'Direct Line'
            end

            phone_text = phone_text.gsub(match_before_number[0], '')
          end

          if phone_type == 'Phone'
            text_after_last_digit = phone_text.match(/\d[^\d]*$/)&.to_s&.gsub(/^\d/, '')&.downcase || ''
            if !text_after_last_digit.empty?
              if text_after_last_digit.include?('mobile') || text_after_last_digit.include?('movil') || 
                text_after_last_digit.include?('móvil') || text_after_last_digit.include?('cell')
                phone_type = 'Mobile'
              elsif text_after_last_digit.include?('office') || text_after_last_digit.include?('oficina') || text_after_last_digit.include?('work') ||
                text_after_last_digit.include?('trabajo')
                phone_type = 'Office'
              elsif text_after_last_digit.include?('fax')
                phone_type = 'Fax'
              elsif text_after_last_digit.include?('direct') && text_after_last_digit.include?("line")
                phone_type = 'Direct Line'
              end
            end
          end

          # Get digits including ., spaces, (, ), +
          digits = phone_text.gsub(/[^\+\d\s\.\(\)-]/, '').gsub(/(\+\s+\+)|(\++)/, '+').gsub(/\s+/, ' ').strip
          digit_count = digits.gsub(/[^\d]/, '').size

          if digit_count < MIN_PHONE_DIGITS || digit_count > MAX_PHONE_DIGITS
            # Too small or long to be a phone number, skip
            next
          end

          country_code = digits.match(/^\+?(\d{1,3})/)&.captures&.first

          phones << {
            type: phone_type,
            phone_number: digits,
            country: PHONES_TO_COUNTRY[country_code],
            extension: extension
          }.compact
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
            next
          else
            isSocialMedia = false
            SOCIAL_MEDIA_URLS.each do |social_media|
              domain = link.downcase.match(/https?:\/\/(www\.)?([^\/]+)/)&.captures&.last || ""
              domain = domain.split('.').first  # Remove TLD

              if social_media == domain
                parsed_links[:social_media][social_media.to_sym] = link.include?("http") ? link : "https://#{link}"
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

    def get_company_name_and_job_title(email_address)
      
      company_name = []
      parsed_titles = []
      acronyms_found = []

      email_domain = email_address.split("@").last&.downcase || ""
      company_domain = ""

      unless COMMON_EMAIL_DOMAINS.any? { |common_domain| email_domain.include?(common_domain) }
        begin
          company_domain = PublicSuffix.parse(email_domain).sld
        rescue Exception => e
          # Dont care
        end
      end
            
      @signature_sentences[0..2]&.each do |sentence|
        if sentence[:type] != 'unknown' && sentence[:type] != 'name'
          next
        end

        text = sentence[:doc].strip()
        if text.include?("@") || text.include?("www") || text.include?("http")
          next
        end

        sections = text.split(',')

        sections.each do |section|
          clean_sentence = section.gsub(/[^\w\s]/, ' ').gsub(/\s+/, ' ').strip
          splitted_text = clean_sentence.split(' ')

          if splitted_text.any? { |word| COMMON_COMPANY_ENDINGS.any? { |ending| word.downcase == ending } }
            company_name = [section]
          end

          if company_name.size == 0 && !company_domain.empty?
            # First attempt to see if section matches company domain, and is the company name
            
            sim = clean_sentence.downcase.gsub(/\s+/, '').similarity(company_domain)
            if (sim >= COMPANY_NAME_SIMILARITY_THRESHOLD)
              company_name = [section]
              if sentence[:type] == 'unknown'
                sentence[:type] = 'company_name_or_job_title'
              end
            end

            if company_name.size == 0
              splitted_text.each do |word|
                sim = word.downcase.similarity(company_domain)
                if sim == 1.0
                  company_name << word.strip()
                  if sentence[:type] == 'unknown'
                    sentence[:type] = 'company_name_or_job_title'
                  end
                  break
                end

                if (sim >= COMPANY_NAME_SIMILARITY_THRESHOLD)
                  if (splitted_text.size <= 3)
                    company_name = splitted_text
                    if sentence[:type] == 'unknown'
                      sentence[:type] = 'company_name_or_job_title'
                    end
                    break
                  else
                    company_name << word.strip()
                    if sentence[:type] == 'unknown'
                      sentence[:type] = 'company_name_or_job_title'
                    end
                  end
                end
              end
            end

            if company_name.size > 0
              next
            end
            # Also compare it with the whole string, without spaces
          end
          # Now try to find job titles in the section
          splitted_downcased_words = splitted_text.map(&:downcase)
          job_titles_found = []

          splitted_downcased_words.each_with_index do |word, index|
            if JOB_TITLES.any?(word)
              job_titles_found << {
                index: index,
                word: word
              }
              if sentence[:type] == 'unknown'
                sentence[:type] = 'company_name_or_job_title'
              end
            end
          end

          acronyms = (section.gsub(/\s+/, ' ').strip.split(' ') & JOB_ACRONYMS)
          if acronyms.size > 0
            acronyms_found += acronyms
            if sentence[:type] == 'unknown'
              sentence[:type] = 'company_name_or_job_title'
            end
          end
          if job_titles_found.size > 0
            parsed_titles << section.gsub(/\s+/, ' ').strip
          end
        end
      end
      
      job_title = {
        titles: parsed_titles,
        acronyms: acronyms_found
      }
      
      return [company_name.uniq.join(" "), job_title]
    end

    def parse_signature(name, email_address, email_body)

      @signature_sentences = []

      get_signature_sentences(name, email_address, email_body)

      address = get_address()
      phones = get_phones()
      links = get_links()
      company_name, job_title = get_company_name_and_job_title(email_address)

      parsed_name = name

      if !parsed_name.nil? && parsed_name.empty?
        if !@parsed_name_from_signature.empty?
          parsed_name = @parsed_name_from_signature
        else
          # Try to extract name from the first two sentences of the signature
          @signature_sentences[0..1].filter{|s| s[:type] == 'unknown'}.each do |sentence|
            sentence_words = sentence[:doc].split(" ")
            if sentence_words.size > 1 && sentence_words.size < 4 && sentence_words.reduce(true){|acc, val| val.size < MAX_NAME_WORD_LENGTH && acc}
              parsed_name = sentence_words.map{|n| n.capitalize}.join(" ")
            end
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
        company_name: company_name,
      }

      return parsed_data
    end

    def split_in_threads(text)

      # Regex for reply markers. Handles English and Spanish.
      # (from|de):\s.*@+.+) matches from followed by an email address
      # (-{5,}\s*?^(from|de):\s+\w+) matches lines that start with ----- followed by from and a name
      marker_regex = /((from|de):\s.*@+.+)|(-{5,}\s*?^(from|de):\s+\w+)/i

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

    def remove_forwarded_content(text)
      if text.nil? || text.empty?
        return text
      end
      # Regex for forwarded message markers. Handles English and Spanish.
      forwarded_regex = /-{5,}.*?(forwarded|reenviado|original)/i
      text.split(forwarded_regex).first&.strip
    end

    def parse_email_html(raw_html)
      content = raw_html[/<html.*<\/html>/im]

      # Gets only the html part of the email
      if content.nil?
        raise InvalidEmailError, "No HTML content found"
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
      if from.nil? || from.empty?
        return name, email_address
      end

      if from.include?("<") && from.include?(">")
        # From likely to include name and email address Name <email@example.com>
        name = from.split("<")&.first&.strip&.gsub((/["']/), '') || ""
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

      # Sometimes when there are special characters in the email, the mail gem fails to parse it correctly
      file_content = File.open(file_path, 'rb') { |f| f.read }
      encoding = file_content[/charset="([^"]+)"/, 1] || file_content[/charset=([^;\s]+)/, 1]
      if !encoding.nil? && !encoding.empty?
        begin 
          file_content = file_content.force_encoding(encoding).encode('UTF-8', invalid: :replace, undef: :replace, replace: '')
        rescue Encoding::UndefinedConversionError, Encoding::InvalidByteSequenceError => e
          # Fallback: force UTF-8 and clean invalid bytes
          file_content = file_content.force_encoding('UTF-8').scrub('?')
        end
      end

      m = Mail.new(file_content)
      from = m.header["From"]&.field&.value
      if from.nil? && from.empty?
        raise InvalidFromError, "No From field in email"
      end

      if from.downcase.include?("reply") || from.downcase.include?("mailer-daemon")
        raise InvalidFromError, "No valid From address"
      end

      name, email_address = extract_name_and_email(from)

      html_part = ""
      text_part = ""

      if m.multipart?
        if m.parts.size > 0
          if !m.html_part.nil?
            if m.html_part.content_type_parameters && !m.html_part.content_type_parameters['charset'].nil? && !m.html_part.content_type_parameters['charset'].empty?
              encoding = m.html_part.content_type_parameters['charset']
            elsif !m.html_part.charset.nil? && !m.html_part.charset.empty?
              encoding = m.html_part.charset
            end

            if !encoding.nil? && !encoding.empty?
              html_part = m.html_part.decode_body.force_encoding(encoding)
            else
              html_part = m.html_part.decode_body.force_encoding('UTF-8')
            end
            begin
              html_part = html_part.encode('UTF-8')
            rescue Encoding::UndefinedConversionError, Encoding::InvalidByteSequenceError => e
              html_part = html_part.encode('UTF-8', invalid: :replace, undef: :replace, replace: '')
            end
            text_part = parse_email_html(html_part)
          else
            text_part = m.text_part ? m.text_part.decode_body : ""
          end
        else
          # If mail detected multipart, but no parts raise error
          raise InvalidEmailError, "Multipart email with no parts"
        end
      else
        raw_content = m.decode_body
        if raw_content.include?("<html")
          text_part = parse_email_html(raw_content)
        else
          text_part = raw_content
        end
      end

      unless !text_part.nil? && !text_part.empty?
        raise InvalidEmailError, "No email body"
      end

      if meeting_email?(text_part)
        raise InvalidEmailError, "Meeting email detected, no signature to parse"
      end

      messages = split_in_threads(text_part)

      # Only parse the first message in the thread, as its the most recent one and the one sent by the from address
      signature = parse_signature(name, email_address.downcase, remove_forwarded_content(messages.first))
      signature[:signature_datetime] = m.date.to_s
      return signature
    end

    def parse_from_html(from, email_html_body)
      unless !from.nil? && !from.empty?
        raise InvalidFromError, "No from provided"
      end

      unless !email_html_body.nil? && !email_html_body.empty?
        raise InvalidEmailError, "No email body provided"
      end

      if from.downcase.include?("reply") || from.downcase.include?("mailer-daemon")
        raise InvalidFromError, "No valid From address"
      end


      name, email_address = extract_name_and_email(from)
      parsed_text = parse_email_html(email_html_body)

      if meeting_email?(parsed_text)
        raise InvalidEmailError, "Email appears to be a meeting invite"
      end

      messages = split_in_threads(parsed_text)

      parse_signature(name, email_address.downcase, remove_forwarded_content(messages.first))
    end

    def parse_from_text(from, email_body)
      unless !from.nil? && !from.empty?
        raise InvalidFromError, "No from provided"
      end

      if from.downcase.include?("reply") || from.downcase.include?("mailer-daemon")
        raise InvalidFromError, "No valid From address"
      end

      if meeting_email?(email_body)
        raise InvalidEmailError, "Email appears to be a meeting invite"
      end
      
      name, email_address = extract_name_and_email(from)
      messages = split_in_threads(email_body)
      
      parse_signature(name, email_address.downcase, remove_forwarded_content(messages.first))
    end
  end
end
