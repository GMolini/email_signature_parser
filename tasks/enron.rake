

require_relative '../lib/email_signature_parser'
require 'json'

desc "Process Enron email data"
task :process_enron_data, [:path, :outpath] do |t, args|
  input_path = args[:path]
  output_path = args[:outpath]

  if input_path.nil? || output_path.nil?
    puts "Usage: rake process_enron_data[path_to_eml_files,output_path]"
    exit 1
  end

  directories = Dir.glob("#{input_path}/*").select { |f| File.directory?(f) }

  total_t1 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  total = 0
  folders_to_process = []
  directories.each do |dir|
    folders = Dir.glob("#{dir}/*").select { |f| File.directory?(f) }
    folders.each do |folder|
      if File.directory?(folder)
        emails = Dir.glob("#{folder}/*").select { |f| File.file?(f) }
        folders_to_process << {
          name: "#{dir.split("/").last}-#{folder.split("/").last}",
          files: emails
        } 
        total += emails.size
      end
    end
  end

  t1 = Process.clock_gettime(Process::CLOCK_MONOTONIC)

  total_processed = 0
  encoding_errors = 0
  folders_to_process.each_with_index do |folder, index|
    p "Processing folder #{index+1}/#{folders_to_process.size} with #{folder[:files].size} emails..."

    folder[:files].each do |file|
      begin
        signature = EmailSignatureParser.from_file(file)
      rescue EmailSignatureParser::ParseError => e
        p "Error processing #{file}: #{e.message}"
        total_processed +=  1
        next
      rescue Encoding::CompatibilityError => e
        p "Error processing #{file}: #{e.message}"
        total_processed +=  1
        encoding_errors += 1
        next
      rescue => e
        p "Error processing #{file}: #{e.message}"
        total_processed +=  1
        raise e
      end

      basename = File.basename(file, ".*")

      if !signature[:address].empty? || signature[:phones].size > 0
        if !Dir.exist?("#{output_path}/#{signature[:email_address]}")
          FileUtils.mkdir_p("#{output_path}/#{signature[:email_address]}")
        end
        outfile = "#{output_path}/#{signature[:email_address]}/#{folder[:name]}_signature_#{basename}.json"
        File.write(outfile, JSON.pretty_generate(signature))
        FileUtils.cp(file, "#{output_path}/#{signature[:email_address]}/#{folder[:name]}_#{basename}_original.txt")
      end

      t2 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      total_processed +=  1
      total_time_until_now = t2 - t1
      avg_time_per_request = total_time_until_now.to_f / total_processed
      eta = (total - total_processed) * avg_time_per_request
      p "Processed, #{total_processed}/#{total} ETA: #{"%02dh:%02dm:%02ds" % [eta / 3600, eta / 60 % 60, eta % 60]}."

    end

    total_t2 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    p "Finished. Encoding errors: #{encoding_errors} out of #{total_processed} processed."
    total_time = total_t2 - total_t1
    p "Total time: #{"%02dh:%02dm:%02ds" % [total_time / 3600, total_time / 60 % 60, total_time % 60]}"
  end
end