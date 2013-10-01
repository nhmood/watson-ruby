module Watson
	class Parser
		# Include for debug_print
		include Watson
	
		# Class Constants
		DEBUG = true 		# Debug printing for this class
	

		# [review] - Not sure if passing config here is best way to access it
		def initialize(config)
			# Identify method entry
			debug_print "#{self} : #{__method__}\n"
			
			@config = config
			@depth = 0
		
		end	

	
		def parse_dir(dir)
			# Identify method entry
			debug_print "#{self} : #{__method__}\n"

			_dir = dir
			# Error check on input
			if (Watson::FS.check_dir(_dir) == false)
				print "Unable to open #{_dir}, exiting\n"
				return false
			else
				debug_print "Opened #{_dir} for parsing\n"
			end
			
			debug_print "Parsing through all files/directories in #{_dir}\n"
			
			# Initialize arrays to store contents we find in this directory
			_completed_dirs = Array.new()
			_completed_files = Array.new()

			# Open directory and get list of all files/directories
			Dir.glob("#{_dir}/*").sort.each do | _entry |
			
				# Create a fully expanded _path to use for reading files/directories
				_path = "#{Dir.pwd}/#{_entry}"
				debug_print "Entry path: #{_path}\n"

				# Make sure this entry isn't part of ignore_list
				# If it is,set to "", which will fail the dir/file check
				# [review] - Warning to user when file is ignored? (outside of debug_print)
				@config.ignore_list.each do | _ignore |
					# Check for any *.type in ignore list (list .swp)
					# Regex to see if extension is .type, ignore if so
					# [review] - Better "Ruby" way to check for "*"? 
					# [review] - Probably cleaner way to perform multiple checks below
					if (_ignore[0] == "*")
						_cut = _ignore[1..-1]
						if (_entry.match(/#{_cut}/))
							debug_print "#{_path} is on the ignore list, setting to \"\"\n"
							_path = ""
							break
						end
					else
						if (_entry == _ignore || _entry == _path)
							debug_print "#{_path} is on the ignore list, setting to \"\"\n"
							_path = ""
							break
						end
					end
				end	


				# Check if entry is a file, if so call parse_file
				if (File.file?(_path))
					debug_print "#{_path} is a file\n"
					parse_file(_path)
				elsif (File.directory?(_path))
					debug_print "#{_path} is a directory\n"	
					
					# If Config.max_depth is 0, no limit on subdirs
					# Else, increment @depth, compare with Config.max_depth
					# If less than depth, parse the dir, else ignore
					# This gets reset in the loop that sends all config/CL dirs through parse_dir
					@depth = @depth + 1
					debug_print "Current Folder depth: #{@depth}\n"
					if (@config.max_depth == 0)
						debug_print "No max depth, parsing directory\n"
						_completed_dirs.push(parse_dir(_path))
					elsif (@depth < config.max_depth)
						debug_print "Depth less than max dept (from config), parsing directory\n"
						_completed_dirs.push(parse_dir(_path))
					else
						debug_print "Depth greater than max depth, ignoring\n"	
					end
				end

				# Add directory to ignore list so it isn't repeated again accidentally
				@config.ignore_list.push(_path)
			end

			# [review] - Not sure if Dir.glob requires a explicit directory/file close?
				
			# Create hash to hold all parsed files and directories
			_structure = Hash.new()
			_structure[:files] = _completed_files
			_structure[:dirs]  = _completed_dirs
			debug_print "Structure: #{_structure}\n"
			return _structure
		end


		# [review] - Rename method input param to filename (more verbose?)
		def parse_file(file)
			# Identify method entry
			debug_print "#{self} : #{__method__}\n"

			_file = file
			# Error check on input
			if (Watson::FS.check_file(_file) == false)
				print "Unable to open #{_file}, exiting\n"
				return false
			else
				debug_print "Opened #{_file} for parsing\n"
			end


			# Get filetype and set corresponding comment type
			if ((_comment = get_comment_type(_file)) == false)
				debug_print "Using default (#) comment type\n"
				_comment = "#"
			end
				
		end


		def get_comment_type(file)
			# Identify method entry
			debug_print "#{self} : #{__method__}\n"

			_file = file
			# Grab the file extension (.something)
			# Check to see whether it is recognized and set comment type
			# If unrecognized, try to grab the next .something extension
			# This is to account for file.cpp.1 or file.cpp.bak, ect

			# [review] - Matz style while loop a la http://stackoverflow.com/a/10713963/1604424
			# Create _mtch var so we can access it outside of the do loop
			 
			_mtch = String.new()
			loop do
				_mtch = _file.match(/(\.(\w+))$/)
				debug_print "Extension: #{_mtch}\n"

				# Break if we don't find a match 
				break if (_mtch == nil)

				# Determine file type
				case _mtch[0]
				# C / C++
				# [todo] - Add /* style comment
				when ".cpp", ".cc", ".c", ".hpp", ".h"
					debug_print "Comment type is: //\n"
					return "//"

				# Bash / Ruby / Perl
				when ".sh", ".rb", ".pl"
					debug_print "Comment type is: #\n"
					return "#"

				# Can't recognize extension, keep looping in case of .bk, .#, ect
				else
					_file.gsub!(/(\.(\w+))$/, "")
					debug_print "Didn't recognize, searching #{_file}\n"
				
				end
			end

			# We didn't find any matches from the filename, return error (0)
			# Deal with what default to use in calling method
			# [review] - Is Ruby convention to return 1 or 0 (or -1) on failure/error?
			debug_print "Couldn't find any recognized extension type\n"
			return false 
		
			
		end 


	end
end
