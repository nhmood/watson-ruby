module Watson
		
		# Color definitions for pretty printing
		# Defined here because we need Global scope but makes sense to have them
		# in the printer.rb file at least

		BOLD  		= "\e[01m"
		UNDERLINE 	= "\e[4m"
		RESET 		= "\e[00m"

		GRAY	= "\e[38;5;0m"
		RED		= "\e[38;5;1m"
		GREEN	= "\e[38;5;2m"
		YELLOW	= "\e[38;5;3m"
		BLUE 	= "\e[38;5;4m"
		MAGENTA	= "\e[38;5;5m"
		CYAN	= "\e[38;5;6m"
		WHITE	= "\e[38;5;7m"


	# Printer class that handles all formatting and printing of parsed dir/file structure
	class Printer
		# [review] - Not sure if the way static methods are defined is correct
		#			 Ok to have same name as instance methods?
		#			 Only difference is where the output gets printed to
		# [review] - No real setup in initialize method, combine it and run method?

		# Include for debug_print (for class methods)
		include Watson

		# Debug printing for this class
		DEBUG = false 		

		class << self
	
		# Include for debug_print (for static methods)
		include Watson

		###########################################################
		# Custom color print for static call (only writes to STDOUT)   
		def cprint (msg = "", color = "")

			# Identify method entry
			debug_print "#{ self } : #{ __method__ }\n"
		
			# This little check will allow us to take a Constant defined color
			# As well as a [0-256] value if specified
			if (color.is_a?(String))	
				debug_print "Custom color specified for cprint\n"
				STDOUT.write(color)
			elsif (color.between?(0, 256))
				debug_print "No or Default color specified for cprint\n"
				STDOUT.write("\e[38;5;#{ color }m")
			end
		
			STDOUT.write(msg)
		end


		###########################################################
		# Standard header print for static call (uses static cprint) 
		def print_header 
		
			# Identify method entry
			debug_print "#{ self } : #{ __method__ }\n"

			# Header
			cprint BOLD + "------------------------------\n" + RESET
			cprint BOLD + "watson" + RESET
			cprint " - " + RESET
			cprint BOLD + YELLOW + "inline issue manager\n" + RESET
			cprint BOLD + "------------------------------\n\n" + RESET

			return true
		end


		###########################################################
		# Status printer for static call (uses static cprint) 
		# Print status block in standard format
		def print_status(msg, color) 
			cprint RESET + BOLD
			cprint WHITE + "[ "
			cprint "#{ msg } ", color
			cprint WHITE + "] " + RESET
		end

		end

		###########################################################
		# Printer initialization method to setup necessary parameters, states, and vars
		def initialize(config)

			# Identify method entry
			debug_print "#{ self } : #{ __method__ }\n"
			
			@config = config
			return true
		end	

		
		###########################################################
		# Take parsed structure and print out in specified formatting 
		def run(structure)

			# Identify method entry
			debug_print "#{ self } : #{ __method__ }\n"
		
			# Check Config to see if we have access to less for printing
			# If so, open our temp file as the output to write to
			# Else, just print out to STDOUT
			if @config.use_less
				debug_print "Unix less avaliable, setting output to #{ @config.tmp_file }\n"
				@output = File.open(@config.tmp_file, 'w')
			elsif
				debug_print "Unix less is unavaliable, setting output to STDOUT\n"
				@output = STDOUT
			end	
			
			# Print header for output
			debug_print "Printing Header\n"
			print_header

			# Print out structure that was passed to this Printer
			debug_print "Starting structure printing\n"
			print_structure(structure)

			# If we are using less, close the output file, display with less, then delete
			if @config.use_less
				@output.close
				# [review] - Way of calling a native Ruby less?
				system("less #{ @config.tmp_file }")
				debug_print "File displayed with less, now deleting...\n"
				File.delete(@config.tmp_file)
			end

			return true
		end


		###########################################################
		# Custom color print for member call
		# Allows not only for custom color printing but writing to file vs STDOUT
		def cprint (msg = "", color = "")

			# Identify method entry
			debug_print "#{ self } : #{ __method__ }\n"

			# This little check will allow us to take a Constant defined color
			# As well as a [0-256] value if specified
			if (color.is_a?(String))	
				debug_print "Custom color specified for cprint\n"
				@output.write(color)
			elsif (color.between?(0, 256))
				debug_print "No or Default color specified for cprint\n"
				@output.write("\e[38;5;#{ color }m")
			end

			@output.write(msg)
		end

	
		###########################################################
		# Standard header print for class call (uses member cprint)
		def print_header 
			# Identify method entry

			debug_print "#{ self } : #{ __method__ }\n"

			# Header
			cprint BOLD + "------------------------------\n" + RESET
			cprint BOLD + "watson" + RESET
			cprint " - " + RESET
			cprint BOLD + YELLOW + "inline issue manager\n\n" + RESET
			cprint "Run in: #{ Dir.pwd }\n"
			cprint "Run @ #{ Time.now.asctime }\n"
			cprint BOLD + "------------------------------\n\n" + RESET

			return true
		end


		###########################################################
		# Status printer for member call (uses member cprint)
		# Print status block in standard format
		def print_status(msg, color) 
			cprint RESET + BOLD
			cprint WHITE + "[ "
			cprint "#{ msg } ", color
			cprint WHITE + "] " + RESET
		end


		###########################################################
		# Go through all files and directories and call necessary printing methods
		# Print all individual entries, call print_structure on each subdir  
		def print_structure(structure)

			# Identify method entry
			debug_print "#{ self } : #{ __method__ }\n"

			# First go through all the files in the current structure
			# The current "structure" should reflect a dir/subdir
			structure[:files].each do | _file |
				debug_print "Printing info for #{ _file }\n"
				print_entry(_file)
			end

			# Next go through all the subdirs and pass them to print_structure
			structure[:subdirs].each do | _subdir |
				debug_print "Entering #{ _subdir } to print further\n"
				print_structure(_subdir)
			end
		end


		###########################################################
		# Individual entry printer
		# Uses issue hash to format printed output
		def print_entry(entry)

			# Identify method entry
			debug_print "#{ self } : #{ __method__ }\n"

			# If no issues for this file, print that and break
			# The filename print is repetative, but reduces another check later
			if entry[:has_issues] == false
				debug_print "No issues for #{ entry }\n"
				print_status "o", GREEN
				cprint BOLD + UNDERLINE + GREEN + "#{ entry[:relative_path] }" + RESET + "\n"
				return true
			else
				debug_print "Issues found for #{ entry }\n"
				cprint "\n"
				print_status "x", RED
				cprint BOLD + UNDERLINE + RED + "#{entry[:relative_path]}" + RESET + "\n"
			end	

	
			# [review] - Should the tag structure be self contained in the hash
			#			 Or is it ok to reference @config to figure out the tags
			@config.tag_list.each do | _tag |
				debug_print "Checking for #{ _tag }\n"

				# [review] - Better way to ignore tags through structure (hash) data
				# Maybe have individual has_issues for each one?
				if entry[_tag].size.zero?
					debug_print "#{ _tag } has no issues, skipping\n"
					cprint "\n"
					next
				end
				
				debug_print "#{ _tag } has issues in it, print!\n"
				print_status "#{ _tag }", BLUE
				cprint "\n"

				# Go through each issue in tag
				entry[_tag].each do | _issue |
					cprint WHITE + "  line #{ _issue[:line_number] } - " + RESET
					cprint BOLD + "#{ _issue[:title] }" + RESET


					# Check to see if it has been resolved on GitHub/Bitbucket
					debug_print "Checking if issue has been resolved\n"	
					@config.github_issues[:closed].each do | _closed | 
						if _closed["body"].include?(_issue[:md5])
							debug_print "Found in #{ _closed[:comment] }, not posting\n"
							cprint BOLD + " [" + RESET
							cprint GREEN + BOLD + "Resolved on GitHub" + RESET
							cprint BOLD + "]" + RESET
						end
						debug_print "Did not find in #{ _closed[:comment] }\n"
					end	

					debug_print "Checking if issue has been resolved\n"
					@config.bitbucket_issues[:closed].each do  | _closed | 
						if _closed["content"].include?(_issue[:md5])
							debug_print "Found in #{ _closed["content"] }, not posting\n"
							cprint BOLD + " [" + RESET
							cprint GREEN + BOLD + "Resolved on Bitbucket" + RESET
							cprint BOLD + "]\n" + RESET
						end
						debug_print "Did not find in #{ _closed["title"] }\n"
					end
					cprint "\n"

				end
				cprint "\n"
			end
		end
	
	end
end 
