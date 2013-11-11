module Watson
	# Configuration container class
	# Contains all configuration options and state variables
	# that are accessed throughout watson
	class Config

		# Include for debug_print
		include Watson
		
		# Debug printing for this class
		DEBUG = false 		
		
		# [review] - Combine into single statement (for performance or something?)
		# [todo] - Add config options (rc file) for default max depth and context lines

		# List of all files/folders to ignore when parsing	
		attr_accessor :ignore_list
		# List of directories to parse	
		attr_accessor :dir_list
		# List of all files to parse
		attr_accessor :file_list		
		# List of tags to look for when parsing
		attr_accessor :tag_list			
		# Number of directories to parse recursively
		attr_accessor :parse_depth
		# Number of lines of issue context to grab
		attr_accessor :context_depth	

		# Flag for command line setting of file/dir to parse
		attr_accessor :cl_entry_set
		# Flag for command line setting of file/dir to ignore
		attr_accessor :cl_ignore_set
		# Flag for command line setting of tag to parse for
		attr_accessor :cl_tag_set		

		# Flag for whether less is avaliable to print results
		attr_reader	  :use_less
		# Flag for where the temp file for printing is located
		attr_reader	  :tmp_file			

		# Flag for whether remote access is avaliable
		attr_accessor :remote_valid		

		# Flag for whether GitHub access is avaliable
		attr_accessor :github_valid
		# GitHub API key generated from Remote::GitHub setup
		attr_accessor :github_api
		# GitHub repo associated with current directory + watson config
		attr_accessor :github_repo
		# Hash to hold list of all GitHub issues associated with repo	
		attr_accessor :github_issues


		# Flag for whether Bitbucket access is avaliable
		attr_accessor :bitbucket_valid
		# Bitbucket API key generated from Remote::Bitbucket setup (username for now)
		attr_accessor :bitbucket_api
		# Bitbucket password for access until OAuth is implemented for Bitbucket
		attr_accessor :bitbucket_pw	
		# Bitbucket repo associated with current directory + watson config
		attr_accessor :bitbucket_repo
		# Hash to hold list of all Bitbucket issues associated with repo	
		attr_accessor :bitbucket_issues	
		

		###########################################################
		# Config initialization method to setup necessary parameters, states, and vars
		def initialize

		# [review] - Read and store rc FP inside initialize?
		# This way we don't need to keep reopening the FP to use it
		# but then we need a way to reliably close the FP when done	
		
			# Identify method entry
			debug_print "#{self.class} : #{__method__}\n"

			# Program config
			@rc_file 		= ".watsonrc"
			@tmp_file 		= ".watsonresults"

			@parse_depth 	= 0
			@context_depth 	= 15

			# State flags
			@cl_entry_set  	= false
			@cl_tag_set 	= false
			@cl_ignore_set 	= false

			# System flags
			# [todo] - Add option to save output to file also
			@use_less = false

			# Data containers
			@ignore_list 	= Array.new()
			@dir_list 		= Array.new()
			@file_list 		= Array.new()
			@tag_list 		= Array.new()
			 
			# Remote options
			@remote_valid 	= false
			
			@github_valid 	= false
			@github_api 	= ""
			@github_repo 	= ""
			@github_issues 	= {:open   => Hash.new(),
							  :closed => Hash.new()
							  }

			# Keep API param (and put username there) for OAuth update later
			@bitbucket_valid 	= false
			@bitbucket_api 		= ""
			@bitbucket_pw 		= ""
			@bitbucket_repo 	= ""
			@bitbucket_issues 	= {:open   => Hash.new(),
								   :closed => Hash.new()
								  }
		end


		###########################################################
		# Parse through configuration and obtain remote info if necessary 
		def run
		
			# Identify method entry
			debug_print "#{ self.class } : #{ __method__ }\n"
			
			# check_conf should create if no conf found, exit entirely if can't do either 
			exit if check_conf == false
			read_conf
			
			unless @github_api.empty? && @github_api.empty?
				Remote::GitHub.get_issues(self)
			end

			unless @bitbucket_api.empty? && @bitbucket_repo.empty?
				Remote::Bitbucket.get_issues(self)
			end
		end


		###########################################################
		# Check for config file in directory of execution
		# Should have individual .rc for each dir that watson is used in
		# This allows you to keep different preferences for different projects
		# Create conf (with #create_conf) if not found
		def check_conf

			# Identify method entry
			debug_print "#{ self.class } : #{ __method__ }\n"

			# Check for .rc
			# If one doesn't exist, create default one with create_conf method
			if !Watson::FS.check_file(@rc_file)
				debug_print "#{ @rc_file } not found\n"
				debug_print "Creating default #{ @rc_file }\n"
				
				# Create default .rc and return create_conf (true if created,
				# false if not)
				return create_conf
			else
				debug_print "#{ @rc_file } found\n"
				return true 
			end
		end


		###########################################################
		# Watson config creater
		# Copies default config from /assets/defaultConf to the current directory
		def create_conf
		# [review] - Not sure if I should use the open/read/write or Fileutils.cp
		
			# Identify method entry
			debug_print "#{ self.class } : #{ __method__ }\n"

			
			# Generate full path since File doesn't care about the LOAD_PATH
			# [review] - gsub uses (.?)+ to grab anything after lib (optional), better regex? 
			_full_path = __dir__.gsub(/\/lib(.?)+/, '') + "/" + "assets/defaultConf"
			debug_print "Full path to defaultConf (in gem): #{ _full_path }\n"
			
			# Check to make sure we can access the default file
			if !Watson::FS.check_file(_full_path)
				print "Unable to open #{ _full_path }\n"
				print "Cannot create default, exiting...\n"
				return false
			else
				# Open default config file in read mode and read into temp
				_input = File.open(_full_path, 'r')
				_default = _input.read

				# Open rc file in current directory in write mode and write default
				_output = File.open(@rc_file, 'w')
				_output.write(_default)
				
				# Close both default and new rc files
				_input.close
				_output.close

				debug_print "Successfully wrote defaultConf to current directory\n"
				return true
			end	
		end


		###########################################################
		# Read configuration file and populate Config container class 
		def read_conf

			# Identify method entry
			debug_print "#{ self.class } : #{ __method__ }\n"
			

			debug_print "Reading #{ @rc_file }\n"
			if !Watson::FS.check_file(@rc_file)
				print "Unable to open #{@rc_file}, exiting\n"
				return false
			else
				debug_print "Opened #{ @rc_file } for reading\n"
			end


			# Check if system has less for output
			@use_less = check_less


			# Add all the standard items to ignorelist	
			# This gets added regardless of ignore list specified
			# [review] - Keep *.swp in there?
			# [todo] - Add conditional to @rc_file such that if passed by -f we accept it
			# [todo] - Add current file (watson) to avoid accidentally printing app tags 
			@ignore_list.push(".")
			@ignore_list.push("..")
			@ignore_list.push("*.swp")
			@ignore_list.push(@rc_file)
			@ignore_list.push(@tmp_file)

			# Open and read rc
			# [review] - Not sure if explicit file close is required here
			_rc = File.open(@rc_file, 'r').read
			
			debug_print "\n\n"	
			
			# Create temp section var to keep track of what we are populating in config
			_section = ""
			
			# Keep index to print what line we are on
			# Could fool around with Enumerable + each_with_index but oh well
			_i = 0;

			# Fix line endings so we can support Windows/Linux edited rc files
			_rc.gsub!(/\r\n?/, "\n")
			_rc.each_line do | _line |
				debug_print "#{ _i }: #{ _line }" if (_line != "\n")
				_i = _i + 1


				# Ignore full line comments or newlines
				if _line.match(/(^#)|(^\n)|(^ )/)
					debug_print "Full line comment or newline found, skipping\n"
					# [review] - More "Ruby" way of going to next line?
					next
				end
	
	
				# [review] - Use if with match so we can call next on the line reading loop
				# Tried using match(){|_mtch|} as well as do |_mtch| but those don't seem to
				# register the next call to the outer loop, so this way will do for now

				# Regex on line to find out if we are in a new [section] of
				# config parameters. If so, store it into section var and move
				# to next line 
				_mtch = _line.match(/^\[(\w+)\]/)
				if _mtch
					debug_print "Found section #{ _mtch[1] }\n"
					_section = _mtch[1]
					next
				end


				case _section
				when "context"
					# No need for regex on context value, command should read this in only as a # 
					# Chomp to get rid of any nonsense
					@context_depth = _line.chomp!


				when "dirs"
					# If @dir_list or @file_list wasn't populated by CL args
					# then populate from rc
					# [review] - Populate @dirs/files_list first, then check size instead
					if @cl_entry_set
						debug_print "Directories or files set from command line ignoring rc [dirs]\n"
						next 
					end
					
					# Regex to grab directory
					# Then substitute trailing / (necessary for later formatting)
					# Then push to @dir_list
					_mtch = _line.match(/^((\w+)?\.?\/?)+/)[0].gsub(/(\/)+$/, "")
					if !_mtch.empty?
						@dir_list.push(_mtch) 
						debug_print "#{ _mtch } added to @dir_list\n"
					end
					debug_print "@dir_list --> #{ @dir_list }\n"
					

				when "tags"
					# Same as previous for tags	
					# [review] - Populate @tag_list, then check size instead
					if @cl_tag_set
						debug_print "Tags set from command line, ignoring rc [tags]\n"
						next 
					end

					# Same as previous for tags
					# [review] - Need to think about what kind of tags this supports
					# Check compatibility with GitHub + Bitbucket and what makes sense
					# Only supports single word+number tags
					_mtch = _line.match(/^(\S+)/)[0]
					if !_mtch.empty?
						@tag_list.push(_mtch)
						debug_print "#{ _mtch } added to @tag_list\n"
					end
					debug_print "@tag_list --> #{ @tag_list }\n"
				

				when "ignore"
					# Same as previous for ignores
					# [review] - Populate @tag_list, then check size instead
					
					if @cl_ignore_set
						debug_print "Ignores set from command line, ignoring rc [ignores]\n"
						next
					end
					
					# Same as previous for ignores (regex same as dirs)
					# Don't eliminate trailing / because not sure if dir can have
					# same name as file (Linux it can't, but not sure about Win/Mac)
					# [review] - Can Win/Mac have dir + file with same name in same dir?
					_mtch = _line.match(/^((\w+)?\.?\/?)+/)[0]
					if !_mtch.empty?
						@ignore_list.push(_mtch) 
						debug_print "#{ _mtch } added to @ignore_list\n"
					end
					debug_print "@ignore_list --> #{ @ignore_list }\n"

				
				when "github_api"
					# No need for regex on API key, GitHub setup should do this properly
					# Chomp to get rid of any nonsense
					@github_api = _line.chomp!
					debug_print "GitHub API: #{ @github_api }\n"

				
				when "github_repo"
					# Same as above
					@github_repo = _line.chomp!
					debug_print "GitHub Repo: #{ @github_repo }\n"


				when "bitbucket_api"
					# Same as GitHub parse above
					@bitbucket_api = _line.chomp!
					debug_print "Bitbucket API: #{ @bitbucket_api }\n"	
	
	
				when "bitbucket_repo"
					# Same as GitHub repo parse above
					@bitbucket_repo = _line.chomp!
					debug_print "Bitbucket Repo: #{ @bitbucket_repo }\n"


				else	
					debug_print "Unknown tag found #{_section}\n"						
				end

			end
		end


		###########################################################
		# Update config file with specified parameters
		# Accepts input parameters that should be updated and writes to file
		# Selective updating to make bookkeeping easier
		def update_conf(*params)

			# Identify method entry
			debug_print "#{ self.class } : #{ __method__ }\n"

			# Check if RC exists, if not create one
			if !Watson::FS.check_file(@rc_file)
				print "Unable to open #{ @rc_file }, exiting\n"
				create_conf
			else
				debug_print "Opened #{ @rc_file } for reading\n"
			end

			# Go through all given params and make sure they are actually config vars
			params.each_with_index do | _param, _i |
				if !self.instance_variable_defined?("@#{ _param }")
					debug_print "#{ _param } does not exist in Config\n"
					debug_print "Check your input(s) to update_conf\n"
					params.slice!(_i)
				end
			end	

			
			# Read in currently saved RC and go through it line by line
			# Only update params that were passed to update_conf
			# This allows us to clean up the config file at the same time

			
			# Open and read rc
			# [review] - Not sure if explicit file close is required here
			_rc = File.open(@rc_file, 'r').read
			_update = File.open(@rc_file, 'w')
			
			
			# Keep index to print what line we are on
			# Could fool around with Enumerable + each_with_index but oh well
			_i = 0;

			# Keep track of newlines for prettying up the conf
			_nlc = 0
			_section = ""

			# Fix line endings so we can support Windows/Linux edited rc files
			_rc.gsub!(/\r\n?/, "\n")
			_rc.each_line do | _line |
				# Print line for debug purposes
				debug_print "#{ _i }: #{ _line }"
				_i = _i + 1

				
				# Look for sections and set section var
				_mtch = _line.match(/^\[(\w+)\]/)
				if _mtch
					debug_print "Found section #{ _mtch[1] }\n"
					_section = _mtch[1]
				end

				# Check for newlines
				# If we already have 2 newlines before any actual content, skip
				# This is just to make the RC file output nicer looking
				if _line == "\n"
					debug_print "Newline found\n"
					_nlc = _nlc + 1
					if _nlc < 3
						debug_print "Less than 3 newlines so far, let it print\n"
						_update.write(_line)
					end
				# If the section we are in doesn't match the params passed to update_conf
				# it is safe to write the line over to the new config
				elsif !params.include?(_section)
					debug_print "Current section NOT a param to update\n"
					debug_print "Writing to new rc\n"
					_update.write(_line)
					
					# Reset newline
					_nlc = 0
				end

				debug_print "line: #{ _line }\n"
				debug_print "nlc: #{ _nlc }\n"
			end

			# Make sure there is at least 3 newlines between last section before writing new params
			(2 - _nlc).times do
				_update.write("\n")
			end

			# Now that we have skipped all the things that need to be updated, write them in
			params.each do | _param |
				_update.write("[#{ _param }]\n")
				_update.write("#{ self.instance_variable_get("@#{ _param }") }")
				_update.write("\n\n\n")
			end	
			
			_update.close
		end

	end
end

