module Watson
		
		# Color definitions for pretty printing
		# Defined here because we need Global scope but makes sense to have them
		# in the printer.rb file at least

		BOLD  		= "\e[01m"
		UNDERLINE 	= "\e[4m"
		RESET 		= "\e[00m"

		# Standard colors
		GRAY	= "\e[38;5;0m"
		RED		= "\e[38;5;1m"
		GREEN	= "\e[38;5;2m"
		YELLOW	= "\e[38;5;3m"
		BLUE 	= "\e[38;5;4m"
		MAGENTA	= "\e[38;5;5m"
		CYAN	= "\e[38;5;6m"
		WHITE	= "\e[38;5;7m"


	class Printer
		# [review] - Not sure if the way static methods are defined is correct
		#			 Ok to have same name as instance methods?
		#			 Only difference is where the output gets printed to
		# [review] - No real setup in initialize method, combine it and run method?

		# Include for debug_print
		include Watson

		# Class Constants
		DEBUG = false 		# Debug printing for this class

		class << self
		include Watson

		###########################################################
		# cprint 
		###########################################################
		
		def cprint (msg = "", color = "")
			# Identify method entry
			debug_print "#{self} : #{__method__}\n"
		
			# This little check will allow us to take a Constant defined color
			# As well as a [0-256] value if specified
			if (color.is_a?(String))	
				debug_print "Custom color specified for cprint\n"
				STDOUT.write(color)
			elsif (color.between?(0, 256))
				debug_print "No or Default color specified for cprint\n"
				STDOUT.write("\e[38;5;#{color}m")
			end
		
			STDOUT.write(msg)
		
		end


		###########################################################
		# print_header 
		###########################################################

		def print_header 
			# Identify method entry
			debug_print "#{self} : #{__method__}\n"

			# Header
			cprint BOLD + "------------------------------\n" + RESET
			cprint BOLD + "watson" + RESET
			cprint " - " + RESET
			cprint BOLD + YELLOW + "inline issue manager\n" + RESET
			cprint BOLD + "------------------------------\n\n" + RESET

			return true
		end


	
		###########################################################
		# print_status 
		###########################################################
	
		def print_status(msg, color) 
			cprint RESET + BOLD
			cprint WHITE + "[ "
			cprint "#{msg} ", color
			cprint WHITE + "] " + RESET
		end

		end

		###########################################################
		# initialize 
		###########################################################
	
		def initialize(config)
			# Identify method entry
			debug_print "#{self} : #{__method__}\n"
			
			@config = config
			return true
		end	

		
		###########################################################
		# run 
		###########################################################

		def run(structure)
			# Identify method entry
			debug_print "#{self} : #{__method__}\n"
		
			# Check Config to see if we have access to less for printing
			# If so, open our temp file as the output to write to
			# Else, just print out to STDOUT
			if (@config.use_less)
				debug_print "Unix less avaliable, setting output to #{@config.tmp_file}\n"
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
			if (@config.use_less)
				@output.close	
				system("less #{@config.tmp_file}")
				debug_print "File displayed with less, now deleting...\n"
				File.delete(@config.tmp_file)
			end

			return true
		end

	
		###########################################################
		# print_header 
		###########################################################

		def print_header 
			# Identify method entry
			debug_print "#{self} : #{__method__}\n"

			# Header
			cprint BOLD + "------------------------------\n" + RESET
			cprint BOLD + "watson" + RESET
			cprint " - " + RESET
			cprint BOLD + YELLOW + "inline issue manager\n\n" + RESET
			cprint "Run in: #{Dir.pwd}\n"
			cprint "Run @ #{Time.now.asctime}\n"
			cprint BOLD + "------------------------------\n\n" + RESET

			return true
		end


		###########################################################
		# cprint 
		###########################################################

		def cprint (msg = "", color = "")
			# Identify method entry
			debug_print "#{self} : #{__method__}\n"

			# This little check will allow us to take a Constant defined color
			# As well as a [0-256] value if specified
			if (color.is_a?(String))	
				debug_print "Custom color specified for cprint\n"
				@output.write(color)
			elsif (color.between?(0, 256))
				debug_print "No or Default color specified for cprint\n"
				@output.write("\e[38;5;#{color}m")
			end

			@output.write(msg)

		end

	
		###########################################################
		# print_status 
		###########################################################
	
		def print_status(msg, color) 
			cprint RESET + BOLD
			cprint WHITE + "[ "
			cprint "#{msg} ", color
			cprint WHITE + "] " + RESET
		end


		###########################################################
		# print_structure 
		###########################################################
	
		def print_structure(structure)
			# Identify method entry
			debug_print "#{self} : #{__method__}\n"

			# First go through all the files in the current structure
			# The current "structure" should reflect a dir/subdir
			structure[:files].each do | _file |
				debug_print "Printing info for #{_file}\n"
				print_entry(_file)
			end

			# Next go through all the subdirs and pass them to print_structure
			structure[:subdirs].each do | _subdir |
				debug_print "Entering #{_subdir} to print further\n"
				print_structure(_subdir)
			end


		end


		###########################################################
		# print_entry
		###########################################################
		
		def print_entry(entry)
			# Identify method entry
			debug_print "#{self} : #{__method__}\n"

			# If no issues for this file, print that and break
			# The filename print is repetative, but reduces another check later
			if (entry[:has_issues] == false)
				debug_print "No issues for #{entry}\n"
				print_status "o", GREEN
				cprint BOLD + UNDERLINE + GREEN + "#{entry[:relative_path]}" + RESET + "\n"
				return true
			else
				debug_print "No issues for #{entry}\n"
				cprint "\n"
				print_status "x", RED
				cprint BOLD + UNDERLINE + RED + "#{entry[:relative_path]}" + RESET + "\n"
			end	
	
			# [review] - Should the tag structure be self contained in the hash
			#			 Or is it ok to reference @config to figure out the tags
			@config.tag_list.each do | _tag |
				debug_print "Checking for #{_tag}\n"

				# [review] - Better way to ignore tags through structure (hash) data
				# Maybe have individual has_issues for each one?
				if (entry[_tag].size > 0 )
					debug_print "#{_tag} has issues in it, print!\n"
					print_status "#{_tag}", BLUE
					cprint "\n"
					entry[_tag].each do | _issue |
						cprint WHITE + "  line #{_issue[:line_number]} - " + RESET
						cprint BOLD + "#{_issue[:comment]}\n" + RESET
					end
					cprint "\n"
				end
			end
		end
	
	end
end 
