module Watson
	class Parser
		# Include for debug_print
		include Watson

		# Include for Digest::MD5.hexdigest used in issue creating
		# [review] - Should this require be required higher up or fine here
		require 'digest'
		require 'pp'
		
		# Class Constants
		DEBUG = true 		# Debug printing for this class
	

		###########################################################
		# initialize 
		###########################################################
	
		# [review] - Not sure if passing config here is best way to access it
		def initialize(config)
			# Identify method entry
			debug_print "#{self} : #{__method__}\n"
			
			@config = config

		
		end	


		###########################################################
		# run 
		###########################################################
	
		def run
			# Identify method entry
			debug_print "#{self} : #{__method__}\n"
			
			# We need to parse the FILES that are given from CL
			# Then we can move on and parse all dirs (config + CL)
			# together
			
			# Go through all files added from CL (sort them first)
			# If empty, sort and each will do nothing, no errors
			_completed_dirs = Array.new()
			_completed_files = Array.new()
			if (@config.cl_entry_set == true)
				@config.file_list.sort.each	do | _file |
					_completed_files.push(parse_file(_file))
				end
			end
				
			@config.dir_list.sort.each do | _dir |
				_completed_dirs.push(parse_dir(_dir, 0))
			end	
			
			
			_structure = Hash.new()
			_structure[:files] = _completed_files
			_structure[:subdirs]  = _completed_dirs

			debug_print "_structure dump\n\n"
			debug_print "#{pp(_structure)}"
			debug_print "\n\n"
			
			return _structure
		end	


		###########################################################
		# parse_dir 
		###########################################################
		
		def parse_dir(dir, depth)
			# Identify method entry
			debug_print "#{self} : #{__method__}\n"

			# Error check on input
			if (Watson::FS.check_dir(dir) == false)
				print "Unable to open #{dir}, exiting\n"
				return false
			else
				debug_print "Opened #{dir} for parsing\n"
			end
			
			debug_print "Parsing through all files/directories in #{dir}\n"

			# [review] - Shifted away from single Dir.glob loop to separate for dir/file
			# 			 This duplicates code but is much better for readability
			# 			 Not sure which is preferred?
			

			# Remove leading . or ./
			_glob_dir = dir.gsub(/^\.(\/?)/, '')
			debug_print "_glob_dir: #{_glob_dir}\n"
	

			# Go through directory to find all files
			# Create new array to hold all parsed files
			_completed_files = Array.new()
			Dir.glob("#{_glob_dir}{*,.*}").select { | _fn | File.file?(_fn) }.sort.each do | _entry |
				debug_print "Entry: #{_entry} is a file\n"	
			
			
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
							debug_print "#{_entry} is on the ignore list, setting to \"\"\n"
							_entry = ""
							break
						end
					else
						if ( (_entry  == _ignore) || (File.absolute_path(_entry) == _ignore) )
							debug_print "#{_entry} is on the ignore list, setting to \"\"\n"
							_entry = ""
							break
						end
					end
				end	

				if (!_entry.empty?)
					debug_print "Parsing #{_entry}\n"
					_completed_files.push(parse_file(_entry))
				end	
			
			end
				 
			
			_completed_dirs = Array.new()
			Dir.glob("#{_glob_dir}{*, .*}").select { | _fn | File.directory?(_fn) }.sort.each do | _entry |
				debug_print "Entry: #{_entry} is a dir\n"	
					
				# If Config.max_depth is 0, no limit on subdirs
				# Else, increment @depth, compare with Config.max_depth
				# If less than depth, parse the dir, else ignore
				# This gets reset in the loop that sends all config/CL dirs through parse_dir
				_cur_depth = depth + 1
				debug_print "Current Folder depth: #{_cur_depth}\n"
				if (@config.max_depth == 0)
					debug_print "No max depth, parsing directory\n"
					_completed_dirs.push(parse_dir("#{_entry}/", _cur_depth))
				elsif (_cur_depth < @config.max_depth.to_i)
					debug_print "Depth less than max dept (from config), parsing directory\n"
					_completed_dirs.push(parse_dir("#{_entry}/", _cur_depth))
				else
					debug_print "Depth greater than max depth, ignoring\n"	
				end

				# Add directory to ignore list so it isn't repeated again accidentally
				@config.ignore_list.push(_entry)
			end


			# [review] - Not sure if Dir.glob requires a explicit directory/file close?
				
			# Create hash to hold all parsed files and directories
			_structure = Hash.new()
			_structure[:curdir] = dir
			_structure[:files] = _completed_files
			_structure[:subdirs]  = _completed_dirs
			return _structure
		end


		###########################################################
		# parse_file 
		###########################################################
		# [review] - Rename method input param to filename (more verbose?)
		def parse_file(filename)
			# Identify method entry
			debug_print "#{self} : #{__method__}\n"

			_path = File.absolute_path(filename) 

			# Error check on input, use input filename to make sure relative path is correct
			if (Watson::FS.check_file(filename) == false)
				print "Unable to open #{filename}, exiting\n"
				return false
			else
				debug_print "Opened #{filename} for parsing\n"
				debug_print "Short path: #{filename}\n"
			end


			# Get filetype and set corresponding comment type
			if ((_comment = get_comment_type(filename)) == false)
				debug_print "Using default (#) comment type\n"
				_comment = "#"
			end


			# Open file and read in entire thing into an array
			# Use an array so we can look ahead when creating issues later
			# [review] - Not sure if explicit file close is required here
			# [review] - Better var name than data for read in file?
			_data = Array.new()
			File.open(_path, 'r').read.each_line do | _line |
				_data.push(_line)	
			end

	
			# Initialize tag hash for each tag in config
			_issue_list = Hash.new()
			_issue_list[:relative_path] = filename 
			_issue_list[:absolute_path] = _path
			_issue_list[:has_issues] = false
			@config.tag_list.each do |_tag|
				debug_print "Creating array named #{_tag}\n"
				_issue_list[_tag] = Array.new
			end
			
			# Loop through all array elements and look for issues	
			_data.each_with_index do | _line, _i |

				# Find any comment line with [tag] - text (any comb of space and # acceptable)
				# Using if match to stay consistent (with config.rb) see there for
				# explanation of why I do this (not a good good one persay...)
				if (_mtch = _line.match(/^[#+?\s+?]+\[(\w+)\]\s+-\s+(.+)/) )
					_tag = _mtch[1]

					# Make sure that the tag that was found is something we accept
					# If not, skip it but tell user about an unrecognized tag
					if (@config.tag_list.include?(_tag) == false)
						print "Unknown tag [#{_tag}] found, ignoring\n"
						print "You might want to include it in your RC or with the -t/--tags flag\n"
						next
					end

					# Found a valid match (with recognized tag)
					# Set flag for this issue_list (for file) to indicate that
					_issue_list[:has_issues] = true

					_comment = _mtch[2]
					debug_print "Issue found\n"
					debug_print "Tag: #{_tag}\n"
					debug_print "Issue: #{_comment}\n"	

					# Create hash for each issue found
					_issue = Hash.new
					_issue[:line_number] = _i
					_issue[:comment] = _comment

					# Grab context of issue specified by Config param (+1 to include issue itself)
					_context = _data[_i..(_i + @config.context_lines + 1)]
					debug_print "#{pp(_context)}\n"
	
					# Go through each line of context and determine indentation
					# Used to preserve indentation in post
					_cut = Array.new 
					_context.each do | _line |
						_max = 0
						# Until we reach a non indent OR the line is empty, keep slicin'
						until (!_line.match(/^( |\t|\n)/) || _line.empty?)
							_line = _line.slice(1..-1)
							_max = _max + 1

							debug_print "New line: #{_line}\n"
							debug_print "Max indent: #{_max}\n"
						end
						
						# Push max indent to the _cut array 
						_cut.push(_max)	
					end	
	
					# Print old _context
					debug_print "\n\n Old Context \n"
					debug_print "#{pp(_context)}\n"
					debug_print "\n\n"

					# Trim the context lines to be left aligned but maintain indentation
					# Then add a single \t to the beginning so the Markdown is pretty on GitHub
					_context.map! { | _line | "\t#{_line.slice(_cut.min .. -1)}" }
				
					print("\n\n New Context \n")
					debug_print "#{pp(_context)}\n"
					print("\n\n")

					_issue[:context] = _context
					
					# These are accessible from _issue_list, but we pass individual issues
					# to the poster, so we need this here to reference them
					_issue[:tag] = _tag
					_issue[:path] = filename

					# Generate md5 hash for each specific issue (for bookkeeping)
					_issue[:md5] = ::Digest::MD5.hexdigest("#{_tag}, #{_path}, #{_comment}")
					debug_print "#{_issue}\n"
	
					# If GitHub is valid, pass _issue to GitHub poster function
					# [review] - Keep Remote as a static method and pass config every time?
					#			 Or convert to a regular class and make an instance with @config

					if (@config.github_valid) 
						debug_print "GitHub is valid, posting issue\n"
						Remote::GitHub.post_issue(_issue, @config)
					else
						debug_print "GitHub invalid, not posting issue\n"
					end	


					if (@config.bitbucket_valid)
						debug_print "Bitbucket is valid, posting issue\n"
						Remote::Bitbucket.post_issue(_issue, @config)
					else
						debug_print "Bitbucket invalid, not posting issue\n"
					end


	
					# [review] - Use _tag string as symbol reference in hash or keep as string?
					# Look into to_sym to keep format of all _issue params the same
					_issue_list[_tag].push( _issue )

					
				end


			end
		
			# [review] - Return of parse_file is different than watson-perl
			# Not sure which makes more sense, ruby version seems simpler
			# perl version might have to stay since hash scoping is weird in perl
			debug_print "\nIssue list: #{_issue_list}\n"

			return _issue_list
		end


		###########################################################
		# get_comment_type 
		###########################################################

		def get_comment_type(filename)
			# Identify method entry
			debug_print "#{self} : #{__method__}\n"

			# Grab the file extension (.something)
			# Check to see whether it is recognized and set comment type
			# If unrecognized, try to grab the next .something extension
			# This is to account for file.cpp.1 or file.cpp.bak, ect

			# [review] - Matz style while loop a la http://stackoverflow.com/a/10713963/1604424
			# Create _mtch var so we can access it outside of the do loop
		
			# Initialize _filename to input filename	
			_extension = filename 
			_mtch = String.new()
			loop do
				_mtch = _extension.match(/(\.(\w+))$/)
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
					_extension = _extension.gsub(/(\.(\w+))$/, "")
					debug_print "Didn't recognize, searching #{_extension}\n"
				
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
