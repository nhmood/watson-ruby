module Watson
	class FS 
		# Class Constants
		DEBUG = false 		# Debug printing for this class
	
		class << self
		# [todo] - Not sure whether to make check* methods return FP
		#		   Makes it nice to get it returned and use it but
		#		   not sure how to deal with closing the FP after
		#		   Currently just close inside

		# Include for debug_print
		include Watson
		
			###########################################################
			# check_file 
			###########################################################
		
			def check_file(file)
				# Identify method entry
				debug_print "#{self} : #{__method__}\n"
			
				# [review] - Not sure what to name input argument local var	
				_file = file;

				# Error check for input
				if (_file.length == 0)
					debug_print "No file specified\n" 
					return false
				end

				# Check if file can be opened
				if (File.readable?(_file))
					debug_print "#{_file} exists and opened successfully\n"
					return true
				else
					debug_print "Could not open #{_file}, skipping\n"
					return false
				end					
				
			end


			###########################################################
			# check_dir 
			###########################################################

			def check_dir(dir)
				# Identify method entry
				debug_print "#{self} : #{__method__}\n"
	
				# [review] - Not sure what to name input argument local var	
				_dir = dir;
	
				# Error check for input
				if (_dir.length == 0)
					debug_print "No directory specified\n"
					return false
				end

				# Check if directory exists 
				if (Dir.exists?(_dir))
					debug_print "#{_dir} exists and opened succesfully\n"
					return true
				else
					debug_print "Could not open #{_dir}, skipping\n"
					return false
				end 

			end


		end
	end
end


