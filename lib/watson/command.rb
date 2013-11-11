module Watson
	class Command
		# Class Constants
		DEBUG = false 		# Debug printing for this class
		
		class << self
		include Watson

		# [review] - Should command line args append or overwrite config/RC parameters?
		# 			 Currently we overwrite, maybe add flag to overwrite or not?
			###########################################################
			# initialize 
			###########################################################
		
			def execute(*args)
				# Identify method entry
				debug_print "#{self} : #{__method__}\n"
		
			
				_args = args
		
				# List of possible flags, used later in parsing and for user reference
				_flag_list = ["-c", "--context-depth",
							  "-d", "--dirs",
						 	  "-f", "--files",
							  "-h", "--help",
						 	  "-i", "--ignore",
						 	  "-p", "--parse-depth",
						 	  "-r", "--remote",
						 	  "-t", "--tags",
						 	  "-u", "--update",
							  "-v", "--version"
							 ]


				# If we get the version or help flag, ignore all other flags
				# Just display these and exit
				# Using .index instead of .include? to stay consistent with other checks
				return help   			if args.index('-h') != nil  || args.index('--help')    != nil
				return version			if args.index('-v') != nil  || args.index('--version') != nil



				# If not one of the above then we are performing actual watson stuff
				# Create all the necessary watson components so we can perform
				# all actions associated with command line args


				# Only create Config, don't call run method
				# Populate Config parameters from CL THEN call run to fill in gaps from RC
				# Saves some messy checking and sorting/organizing of parameters
				@config = Watson::Config.new
				@parser = Watson::Parser.new(@config)
				@printer = Watson::Printer.new(@config)
	
				# Capture Ctrl+C interrupt for clean exit
				# [review] - Not sure this is the correct place to put the Ctrl+C capture
				trap("INT") do
					if (File.exists?(@config.tmp_file))
						File.delete(@config.tmp_file)
					end
					exit 2
				end

				# Parse command line options
				# Begin by slicing off until we reach a valid flag
				
				# Always look at first array element in case and then slice off what we need
				# Accept parameters to be added / overwritten if called twice
				# Slice out from argument until next argument
			
				# Clean up argument list by removing elements until the first valid flag	
				until (_flag_list.include?(_args[0]) == true || _args.length == 0) do
					# [review] - Make this non-debug print to user?
					debug_print "Unrecognized flag #{_args[0]}\n"
					_args.slice!(0)

				end
		
				# Parse command line options
				# Grab flag (should be first arg) then slice off args until next flag
				# Repeat until all args have been dealt with

				# Store total number of args prior to slicing, used for setup_remote
				_arg_length = _args.length

				until (_args.length == 0)
					# Set flag for calling function later
					_flag = _args.slice!(0)

					debug_print "Current Flag: #{_flag}\n"

					# Go through args until we find the next valid flag or all args are parsed 
					_i = 0
					until ( (_flag_list.include?(_args[_i]) == true ) || ( _i > (_args.length - 1) ) ) do
						debug_print "Arg: #{_args[_i]}\n"
						_i = _i + 1	
					end
						
					# Slice off the args for the flag (inclusive) using index from above
					# [review] - This is a bit messy (to slice by _i - 1) when we have control
					# over the _i index above but I don't want to
					# think about the logic right now so look at later
					_flag_args = _args.slice!(0..(_i-1))

					case _flag 
					when "-c", "--context-depth"
						debug_print "Found -c/--context-depth argument\n"
						set_context(_flag_args)

					when "-d", "--dirs"
						debug_print "Found -d/--dirs argument\n"
						set_dirs(_flag_args)
					
					when "-f", "--files"
						debug_print "Found -f/--files argument\n"
						set_files(_flag_args)

					when "-i", "--ignore"
						debug_print "Found -i/--ignore argument\n"
						set_ignores(_flag_args)

					when "-p", "--parse-depth"
						debug_print "Found -r/--parse-depth argument\n"
						set_parse_depth(_flag_args)
					
					when "-t", "--tags"
						debug_print "Found -t/--tags argument\n"
						set_tags(_flag_args)

					when "-r", "--remote"
						debug_print "Found -r/--remote argument\n"
						# Run config to populate all the fields and such
						# [review] - Not a fan of running these here but want to avoid getting all issues when running remote (which @config.run does)
						@config.check_conf
						@config.read_conf
						
						setup_remote(_flag_args, _arg_length)
						
						# If setting up remote, exit afterwards
						exit true
					
					when "-u", "--update"
						debug_print "Found -u/--update argument\n"
						@config.remote_valid =  true


					else
						print "Unknown argument #{_flag}\n"
					end
				end

				debug_print "Args length 0, running watson...\n"
				@config.run
				structure = @parser.run
				@printer.run(structure)
			end


			###########################################################
			# help 
			###########################################################
		
			# [todo] - Add bold and colored printing
			def help
				# Identify method entry
				debug_print "#{self} : #{__method__}\n"
				
				print BOLD;
				print "Usage: watson [OPTION]...\n"
    			print "Running watson with no arguments will parse with settings in RC file\n"
    			print "If no RC file exists, default RC file will be created\n"

    			print "\n"
    			print "   -d, --dirs            list of directories to search in\n"
				print "   -c, --context-depth   number of lines of context to provide with posted issue\n"
    			print "   -f, --files           list of files to search in\n"
    			print "   -h, --help            print help\n"
    			print "   -i, --ignore          list of files, directories, or types to ignore\n"
    			print "   -p, --parse-depth     depth to recursively parse directories\n"
    			print "   -r, --remote          list / create tokens for Bitbucket/GitHub\n"
    			print "   -t, --tags            list of tags to search for\n"
    			print "   -u, --update          update remote repos with current issues\n"
    			print "   -v, --version    	 print watson version and info\n"
    			print "\n"

    			print "Any number of files, tags, dirs, and ignores can be listed after flag\n"
    			print "Ignored files should be space separated\n"
    			print "To use *.filetype identifier, encapsulate in \"\" to avoid shell substitutions \n"
    			print "\n"

    			print "Report bugs to: watson\@goosecode.com\n"
    			print "watson home page: <http://goosecode.com/projects/watson>\n"
    			print "[goosecode] labs | 2012-2013\n"
    			print RESET;
			
			    return true

			end


			###########################################################
			# version 
			###########################################################
			
			def version
				# Identify method entry
				debug_print "#{self} : #{__method__}\n"
			
				print "watson v1.0\n"
				print "Copyright (c) 2012-2013 goosecode labs\n"
				print "Licensed under MIT, see LICENSE for details\n"
				print "\n"

				print "Written by nhmood, see <http://goosecode.com/projects/watson>\n"		
				return true
			end


			###########################################################
			# set_context  
			###########################################################
			
			def set_context(args) 
				# Identify method entry
				debug_print "#{self} : #{__method__}\n"
				
				_args = args

				# Need at least one dir in args
				if (_args.length <= 0)
					# [review] - Make this a non-debug print to user?
					debug_print "No args passed, exiting\n"
					return false
				end

			
				# For context_depth we do NOT append to RC, ALWAYS overwrite
				# For each argument passed, make sure valid, then set @config.parse_depth 
				args.each do | _context_depth |
					if (_context_depth.match(/^(\d+)/))
						debug_print "Setting #{_context_depth} to config context_depth\n"	
						@config.context_depth = _context_depth.to_i
					else
						debug_print "#{_context_depth} invalid depth, ignoring\n"
					end
				end

				# Doesn't make much sense to set context_depth for each individual post
				# When you use this command line arg, it writes the config parameter	
				@config.update_conf("context_depth")

				debug_print "Updated context_depth: #{@config.context_depth}\n"
				return true
			end


			###########################################################
			# set_dirs  
			###########################################################
			
			def set_dirs(args) 
				# Identify method entry
				debug_print "#{self} : #{__method__}\n"
				
				_args = args

				# Need at least one dir in args
				if (_args.length <= 0)
					# [review] - Make this a non-debug print to user?
					debug_print "No args passed, exiting\n"
					return false
				end

				# Set config flag for CL entryset  in config
				@config.cl_entry_set = true	
				debug_print "Updated cl_entry_set flag: #{@config.cl_entry_set}\n"
				
				# [review] - Should we clean the dir before adding here?
				# For each argument passed, make sure valid, then add to @config.dir_list
				args.each do | _dir |
					
					# Error check on input
					if (Watson::FS.check_dir(_dir) == false)
						print "Unable to open #{_dir}\n"
					else
						# Clean up directory path
						_dir = _dir.match(/^((\w+)?\.?\/?)+/)[0].gsub(/(\/)+$/, "")
						if _dir.empty? == false
							debug_print "Adding #{_dir} to config dir_list\n"
							@config.dir_list.push(_dir)
						end
					end


				end

				debug_print "Updated dirs: #{@config.dir_list}\n"
				return true
			end


			###########################################################
			# set_files  
			###########################################################
			
			def set_files(args) 
				# Identify method entry
				debug_print "#{self} : #{__method__}\n"
				
				_args = args
				
				# Need at least one file in args
				if (_args.length <= 0)
					debug_print "No args passed, exiting\n"
					return false
				end

				# Set config flag for CL entryset  in config
				@config.cl_entry_set = true	
				debug_print "Updated cl_entry_set flag: #{@config.cl_entry_set}\n"

				# For each argument passed, make sure valid, then add to @config.file_list
				args.each do | _file |
					
					# Error check on input
					if (Watson::FS.check_file(_file) == false)
						print "Unable to open #{_file}\n"
					else
						debug_print "Adding #{_file} to config file_list\n"
						@config.file_list.push(_file)
					end


				end

				debug_print "Updated files: #{@config.file_list}\n"
				return true
			end


			###########################################################
			# set_ignores
			###########################################################
			
			def set_ignores(args)
				# Identify method entry
				debug_print "#{self} : #{__method__}\n"
				
				_args = args
				
				# Need at least one ignore in args
				if (_args.length <= 0)
					debug_print "No args passed, exiting\n"
					return false
				end

				# Set config flag for CL ignore set in config
				@config.cl_ignore_set = true	
				debug_print "Updated cl_ignore_set flag: #{@config.cl_ignore_set}\n"


				# For ignores we do NOT overwrite RC, just append	
				# For each argument passed, add to @config.ignore_list
				args.each do | _ignore |
				
					debug_print "Adding #{_ignore} to config ignore_list\n"
					@config.ignore_list.push(_ignore)

				end

				debug_print "Updated ignores: #{@config.ignore_list}\n"
				return true
			end


			###########################################################
			# set_parse_depth 
			###########################################################
			
			def set_parse_depth(args)
				# Identify method entry
				debug_print "#{self} : #{__method__}\n"
				
				_args = args
			
				# This should be a single, numeric, value
				# If they pass more, just take the last valid value
				if (_args.length <= 0)
					debug_print "No args passed, exiting\n"
					return false
				end

				# For max_dpeth we do NOT append to RC, ALWAYS overwrite	
				# For each argument passed, make sure valid, then set @config.parse_depth 
				args.each do | _parse_depth |
			
					if (_parse_depth.match(/^(\d+)/))
						debug_print "Setting #{_parse_depth} to config parse_depth\n"	
						@config.parse_depth = _parse_depth
					else
						debug_print "#{_parse_depth} invalid depth, ignoring\n"
					end
				end

				debug_print "Updated parse_depth: #{@config.parse_depth}\n"
				return true
			end


			###########################################################
			# set_tags
			###########################################################
			
			def set_tags(args)
				# Identify method entry
				debug_print "#{self} : #{__method__}\n"
				
				_args = args
				
				# Need at least one tag in args
				if (_args.length <= 0)
					debug_print "No args passed, exiting\n"
					return false
				end
				
				# Set config flag for CL tag set in config
				@config.cl_tag_set = true	
				debug_print "Updated cl_tag_set flag: #{@config.cl_tag_set}\n"

				# If set from CL, we overwrite the RC parameters
				# For each argument passed, add to @config.tag_list
				args.each do | _tag |
				
					debug_print "Adding #{_tag} to config tag_list\n"
					@config.tag_list.push(_tag)

				end

				debug_print "Updated tags: #{@config.tag_list}\n"
				return true
			end


			###########################################################
			# setup_remote
			###########################################################
			
			def setup_remote(args, length)
				# Identify method entry
				debug_print "#{self} : #{__method__}\n"
				
				_args = args
				_length = length
				
				# When generating Oauth Token for GitHub/Bitbucket
				# no other params should be passed, _length is all params passed
				if (_length > 2)
					debug_print "To view or add associated GitHub/Bitbucket repos please pass"
					debug_print "remote flag (-r/--remote) alone\n"
					debug_print "See help (-h/--help) for details\n\n"
					return false
				end

			
				if (_args.length == 1)	
					if (_args[0].downcase == "github")        
						debug_print "GitHub setup called from CL\n"
						Watson::Remote::GitHub.setup(@config) 

					elsif (_args[0].downcase =="bitbucket") 
						debug_print "Bitbucket setup called from CL\n"
						Watson::Remote::Bitbucket.setup(@config) 

					else
						debug_print "Incorrect arguments passed\n"
						debug_print "Please specify either Github or Bitbucket to setup remote\n"
						debug_print "Or pass without argument to see current remotes\n"
						debug_print "See help (-h/--help) for more details\n"
						return false
					end

				else 
					# Check the config for any remote entries (GitHub or Bitbucket) and print
					# We *should* always have a repo + API together, but API should be enough
					if (@config.github_api.empty? && @config.bitbucket_api.empty?)
						debug_print "No remotes currently exist\n"
						debug_print "Pass github or bitbucket to watson -r/--remote to add\n"
						debug_print "See help (-h/--help) for more details\n"

						return false
					end

					if (@config.github_api.empty? == false)
						debug_print "GitHub User : #{@config.github_api}\n"
						debug_print "GitHub Repo : #{@config.github_repo}\n"
					end

					if (@config.bitbucket_api.empty? == false)
						debug_print "Bitbucket User : #{@config.bitbucket_api}\n"
						debug_print "Bitbucket Repo : #{@config.bitbucket_repo}\n"
					end
				end
					
			end




		end
	end
end



