module Watson::Formatters
  class DefaultFormatter < BaseFormatter
    def run(structure)
      debug_print "#{self} : #{__method__}\n"

      output_result do
        # Check Config to see if we have access to less for printing
        # If so, open our temp file as the output to write to
        # Else, just print out to STDOUT
        # Print header for output
        debug_print "Printing Header\n"

        print_header

        # Print out structure that was passed to this Printer
        debug_print "Starting structure printing\n"
        print_structure(structure)
      end
    end

    private

    def output_result(&block)
      debug_print "#{self} : #{__method__}\n"
      @output ||= begin
        if @config.use_less
          debug_print "Unix less avaliable, setting output to #{@config.tmp_file}\n"
          File.open(@config.tmp_file, 'w')
        else
          debug_print "Unix less is unavaliable, setting output to STDOUT\n"
          STDOUT
        end
      end

      yield

      # If we are using less, close the output file, display with less, then delete
      if @config.use_less
        @output.close
        # [review] - Way of calling a native Ruby less?
        system("less -R #{@config.tmp_file}")
        debug_print "File displayed with less, now deleting...\n"
        File.delete(@config.tmp_file)
      end
    end

    ###########################################################
    # Standard header print for class call (uses member cprint)
    def print_header
      # Identify method entry
      debug_print "#{ self } : #{ __method__ }\n"

      # Header
      cprint <<-MESSAGE.gsub(/^ {6}/, '')
      #{BOLD}------------------------------#{RESET}
      #{BOLD}watson#{RESET} - #{RESET} #{BOLD}#{YELLOW}inline issue manager#{RESET}

      Run in: #{Dir.pwd}
      Run @ #{Time.now.asctime}
      #{BOLD}------------------------------\n#{RESET}
      MESSAGE
    end

    ###########################################################
    # Go through all files and directories and call necessary printing methods
    # Print all individual entries, call print_structure on each subdir
    def print_structure(structure)
      # Identify method entry
      debug_print "#{self} : #{__method__}\n"

      # First go through all the files in the current structure
      # The current "structure" should reflect a dir/subdir
      structure[:files].each do |file|
        debug_print "Printing info for #{file}\n"
        print_entry(file)
      end

      # Next go through all the subdirs and pass them to print_structure
      structure[:subdirs].each do |subdir|
        debug_print "Entering #{subdir} to print further\n"
        print_structure(subdir)
      end
    end

    ###########################################################
    # Individual entry printer
    # Uses issue hash to format printed output
    def print_entry(entry)
      # Identify method entry
      debug_print "#{self} : #{__method__}\n"

      # If no issues for this file, print that and break
      # The filename print is repetative, but reduces another check later
      if entry[:has_issues]
        return true if @config.show_type == 'clean'

        debug_print "Issues found for #{entry}\n"
        cprint "\n"
        print_status 'x', RED
        cprint " #{BOLD}#{UNDERLINE}#{RED}#{entry[:relative_path]}#{RESET}\n"
      else
        unless @config.show_type == 'dirty'
          debug_print "No issues for #{entry}\n"
          print_status 'o', GREEN
          cprint " #{BOLD}#{UNDERLINE}#{GREEN}#{entry[:relative_path]}#{RESET}\n"
          return true
        end
      end

      # [review] - Should the tag structure be self contained in the hash
      #      Or is it ok to reference @config to figure out the tags
      @config.tag_list.each do | tag |
        debug_print "Checking for #{ tag }\n"
        print_tag(tag, entry)
      end
    end

    def print_tag(tag, entry)
      # [review] - Better way to ignore tags through structure (hash) data
      # Maybe have individual has_issues for each one?
      if entry[tag].size.zero?
        debug_print "#{ tag } has no issues, skipping\n"
        return
      end

      debug_print "#{tag} has issues in it, print!\n"
      print_status "#{tag}", BLUE
      cprint "\n"

      # Go through each issue in tag
      entry[tag].each do |issue|
        cprint "#{WHITE}  line #{issue[:line_number]} - #{RESET}#{BOLD}#{issue[:title]}#{RESET}"

        # Check to see if it has been resolved on GitHub/Bitbucket
        debug_print "Checking if issue has been resolved\n"
        @config.github_issues[:closed].each do | _closed |
          if _closed["body"].include?(issue[:md5])
            debug_print "Found in #{ _closed[:comment] }, not posting\n"
            cprint <<-MESSAGE.gsub(/^ {13}/, '')
            #{BOLD} [#{RESET}#{GREEN}#{BOLD}Resolved on GitHub#{RESET}#{BOLD}]#{RESET}
            MESSAGE
          end
          debug_print "Did not find in #{ _closed[:comment] }\n"
        end

        debug_print "Checking if issue has been resolved\n"
        @config.bitbucket_issues[:closed].each do  |closed|
          if closed['content'].include?(issue[:md5])
            debug_print "Found in #{ closed["content"] }, not posting\n"
            cprint <<-MESSAGE.gsub(/^ {13}/, '')
            #{BOLD} [#{RESET}#{GREEN}#{BOLD}Resolved on Bitbucket#{RESET}#{BOLD}]#{RESET}
            MESSAGE
          end
          debug_print "Did not find in #{ closed["title"] }\n"
        end

        cprint "\n"
      end

      cprint "\n"
    end

    ###########################################################
    # Custom color print for member call
    # Allows not only for custom color printing but writing to file vs STDOUT
    def cprint(msg = '', color = '')
      # Identify method entry
      debug_print "#{self} : #{__method__}\n"

      # This little check will allow us to take a Constant defined color
      # As well as a [0-256] value if specified
      if color.is_a?(String)
        debug_print "Custom color specified for cprint\n"
        @output.write(color)
      elsif color.between?(0, 256)
        debug_print "No or Default color specified for cprint\n"
        @output.write("\e[38;5;#{color}m")
      end

      @output.write(msg)
    end

    ###########################################################
    # Status printer for member call (uses member cprint)
    # Print status block in standard format
    def print_status(msg, color)
      cprint "#{RESET}#{BOLD}#{WHITE}[ "
      cprint "#{msg} ", color
      cprint "#{WHITE}]#{RESET}"
    end
  end
end
