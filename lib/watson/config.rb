module Watson
	class Config

		def initialize
			# Program config
			# [reviewme] - Should these be $ or @ vars?
			@RCNAME = ".watsonrc"
			@TMPOUT = ".watsonresults"


			# State flags


			# Data containers


			 
		end


		# Check for config file in directory of execution
		# If it doesn't exist, create the default one
		def checkConf
			# Should have individual .rc for each dir that watson is used in
			# This allows you to keep different preferences for different projects

			# Check for rc
			print "[Checking for #{@RCNAME}]\n"
			if (Watson::FS.checkFile(@RCNAME) == false)
				print "#{@RCNAME} not found\n"
				print "Creating default #{@RCNAME}\n"
				
				# Create default RC
				createConf
				return false
			else
				print "#{@RCNAME} found\n\n"
				return true
			end
		end


		# Copy default config in /assets/defaultConf to the current 
		# directory
		def createConf
			# Check to make sure we can access the default file
			# [review] - How does this relative path work with gems?
			if (Watson::FS.checkFile('assets/defaultConf') == false)
				print "Unable to open assets/defaultConf\n"
				print "Cannot create default\n"
				return false	
			else
				# Open default config file in read mode
				input = File.open('assets/defaultConf', 'r')
				# Read data into temporary var
				default = input.read()

				# Open RC file in current directory in write mode
				output = File.open(@RCNAME, 'w')
				# Write default config to RC in current directory
				output.write(default)
				
				# Close both default and new RC files
				input.close()
				output.close()

				return true
			end	
		end


		def readConf
			

		end



		



	end
end

