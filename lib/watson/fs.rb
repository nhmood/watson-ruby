# [todo] - Not sure whether to make check* methods return FP
#		   Makes it nice to get it returned and use it but
#		   not sure how to deal with closing the FP after
#		   Currently just close inside

module Watson
	class FS 
		class << self
		
			# [todo] - Find a better name than this maybe	
			def checkFile(file)
				@file = file;

				# Error check for input
				if (@file.length == 0)
					print "No file specified.\n" 
					return false
				end

				# Check if file can be opened
				if (File.readable?(@file))
					print "#{@file} exists and opened successfully.\n"
					return true
				else
					print "Could not open #{@file}, skipping.\n"
					return false
				end					
				
			end

			# [todo] - Find a better name than this maybe
			def checkDir(dir)
				@dir = dir;
		
				# Error check for input
				if (@dir.length == 0)
					print "No directory specified\n"
					return false
				end

				# Check if directory exists 
				if (Dir.exists?(@dir))
					print "#{@dir} exists and opened succesfully.\n"
					return true
				else
					print "Could not open #{@dir}, skipping.\n"
					return false
				end 

			end

		end

	end
end


