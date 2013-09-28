module Watson
	class Config
		# Include for debug_print
		include Watson
		
		# Class Constants
		DEBUG = true 		# Debug printing for this class
		

		def initialize
		# Initialize class parameters/state/vars 

		# [review] - Read and store rc FP inside initialize?
		# This way we don't need to keep reopening the FP to use it
		# but then we need a way to reliably close the FP when done	
		
			# Identify method entry
			debug_print "#{self.class} : #{__method__}\n"

			# Program config
			@rc_file = ".watsonrc"
			@tmp_file = ".watsonresults"

			# State flags
			@rc_dir_ignore  = false
			@rc_file_ignore = false

			# Data containers
			@ignore_list = Array.new()
			@dir_list = Array.new()
			@tag_list = Array.new()
			 
		end


		def check_conf
		# Check for config file in directory of execution
		# Should have individual .rc for each dir that watson is used in
		# This allows you to keep different preferences for different projects

			# Identify method entry
			debug_print "#{self.class} : #{__method__}\n"

			# Check for .rc
			# If one doesn't exist, create default one with create_conf method
			if (Watson::FS.check_file(@rc_file) == false)
				debug_print "#{@rc_file} not found\n"
				debug_print "Creating default #{@rc_file}\n"
				
				# Create default .rc and return create_conf (true if created,
				# false if not)
				return create_conf
			else
				debug_print "#{@rc_file} found\n"
				return true
			end
		end


		def create_conf
		# Copy default config from /assets/defaultConf to the current directory
		# [review] - Not sure if I should use the open/read/write or Fileutils.cp
		
			# Identify method entry
			debug_print "#{self.class} : #{__method__}\n"

			# Check to make sure we can access the default file
			if (Watson::FS.check_file('assets/defaultConf') == false)
				print "Unable to open assets/defaultConf\n"
				print "Cannot create default, exiting...\n"
				return false	
			else
				# Open default config file in read mode
				_input = File.open('assets/defaultConf', 'r')
				# Read data into temporary var
				_default = _input.read()

				# Open rc file in current directory in write mode
				_output = File.open(@rc_file, 'w')
				# Write default config to rc in current directory
				_output.write(_default)
				
				# Close both default and new rc files
				_input.close()
				_output.close()

				debug_print "Successfully wrote defaultConf to current directory\n"
				return true
			end	
		end


		def read_conf
		# Config file reader that populates Config class parameters

			# Identify method entry
			debug_print "#{self.class} : #{__method__}\n"
			debug_print "Reading #{@rc_file}\n"

			if (Watson::FS.check_file(@rc_file) == false)
				print "Unable to open #{@rc_file}, exiting\n"
				return false
			else
				debug_print "Opened #{@rc_file} for reading\n"
			end


			# Add all the standard dirs to ignorelist	
			@ignore_list.push(".")
			@ignore_list.push("..")
			@ignore_list.push("*.swp")
			@ignore_list.push(@rc_file)
			@ignore_list.push(@tmp_file)

			# Open and read rc
			# [review] - Not sure if explicit file close is required here
			_rc = File.open(@rc_file, 'r').read
			
			# Add spacing in debug print before line printing
			debug_print "\n\n"	
			
			# Create temp section var to keep track of what we are populating in config
			_section = ""
			

			# Keep index to print what line we are on
			# Could fool around with Enumerable + each_with_index but oh well
			_i = 0;

			# Fix line endings so we can support Windows/Linux edited rc files
			_rc.gsub!(/\r\n?/, "\n")
			_rc.each_line do | _line |
				# Print line for debug purposes
				debug_print "#{_i}: #{ _line}" if (_line != "\n")
				_i = _i + 1


				# Ignore full line comments or newlines
				if _line.match(/(^#)|(^\n)|(^ )/)
					debug_print "Full line comment or newline found, skipping\n"
					# [review] - More "Ruby" way of going to next line?
					next
				end
	
	
				# [review] - Use if with match so we can call next on the line reading loop
				# Tried using match(){|_mtch|} as well as do |_mtch| but those don't seem to
				# register the next call to the outer loop, so this method will do for now

				# Regex on line to find out if we are in a new [section] of
				# config parameters. If so, store it into section var and move
				# to next line 
				if (_mtch = _line.match(/^\[(\w+)\]/))
					debug_print "Found section #{_mtch[1]}\n"
					_section = _mtch[1]
					next
				end


				case _section
				when "dirs"
					# If @dir_list or @file_list wasn't populated by CL args
					# then populate from rc
					# [review] - Populate @dirs/files_list first, then check size instead
					if (@rc_dirs_ignore == true || @rc_files_ignore == true)
						debug_print "Directories or files set from command line," \
									"ignoring rc [dirs]\n"
						next 
					else
						# Regex to grab directory
						# Then substitute trailing / (necessary for later formatting)
						# Then push to @dir_list

						_mtch = _line.match(/^((\w+)?\.?\/?)+/)[0].gsub(/(\/)+$/, "")
						if _mtch.empty? == false
							@dir_list.push(_mtch) 
							debug_print "#{_mtch} added to @dir_list\n"
						end
						debug_print "@dir_list --> #{@dir_list}\n"
					end	

				when "tags"
					# Same as previous for tags	
					# [review] - Populate @tag_list, then check size instead
					if (@rc_tags_ignore == true)
						debug_print "Tags set from command line, ignoring rc [tags]\n"
						next 
					else
						# Same as previous for tags
						# [review] - Need to think about what kind of tags this supports
						# Check compatibility with GitHub + Bitbucket and what makes sense
						# Only supports single word+number tags
						_mtch = _line.match(/^(\S+)/)[0]
						if _mtch.empty? == false
							@tag_list.push(_mtch)
							debug_print "#{_mtch} added to @tag_list\n"
						end
						debug_print "@tag_list --> #{@tag_list}\n"
					end
				

				when "ignore"
					# Same as previous for ignores
					# [review] - Populate @tag_list, then check size instead
					
					# Great var name, I know
					if (@rc_ignore_ignore == true)
						debug_print "Ignores set from command line, ignoring rc [ignores]\n"
						next 
					else
						# Same as previous for ignores (regex same as dirs)
						# Don't eliminate trailing / because not sure if dir can have
						# same name as file (Linux it can't, but not sure about Win/Mac)
						# [review] - Can Win/Mac have dir + file with same name in same dir?
						_mtch = _line.match(/^((\w+)?\.?\/?)+/)[0]
						if _mtch.empty? == false
							@ignore_list.push(_mtch) 
							debug_print "#{_mtch} added to @ignore_list\n"
						end
						debug_print "@ignore_list --> #{@ignore_list}\n"
					end

				
				when "github"
					# No need for regex on API key, GitHub setup should do this properly
					# Chomp to get rid of any nonsense
					@github_api = line.chomp!
					debug_print "GitHub API: #{@github_api}\n"

				
				when "githubrepo"
					# Same as above
					@github_repo = line.chomp!
					debug_print "GitHub Repo: #{@github_repo}\n"


				when "bitbucket"
					# Same as GitHub parse above
					@bitbucket_api = line.chomp!
					debug_print "Bitbucket API: #{@bitbucket_api}\n"	
		
				when "bitbucketrepo"
					# Same as GitHub repo parse above
					@bitbucket_repo = line.chomp!
					debug_print "Bitbucket Repo: #{@bitbucket_repo}\n"

				else	
					debug_print "Unknown tag found #{_section}\n"						
				end

			end
		end



	end
end

