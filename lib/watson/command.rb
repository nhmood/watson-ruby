module Watson
	class Command
		class << self
	
			###########################################################
			# initialize 
			###########################################################
		
			def execute(*args)
				# If we get the version or help flag, ignore all other flags
				# Just display these and exit
				return help   			if args.include?('-h')  || args.include?('--help')
				return version			if args.include?('-v')  || args.include?('--version')

				# If not one of the above then we are performing actual watson stuff
				# Create all the necessary watson components so we can perform
				# all actions associated with command line args

				#config = Watson::Config.new
				
	
				# Parse command line options and fill in our 			
					

			end


			###########################################################
			# help 
			###########################################################
		
			# [todo] - Add bold and colored printing
			def help
				# print BOLD;
				print "Usage: watson [OPTION]...\n"
    			print "Running watson with no arguments will parse with settings in RC file\n"
    			print "If no RC file exists, default RC file will be created\n"

    			print "\n"
    			print "   -d, --dirs            list of directories to search in\n"
    			print "   -f, --files           list of files to search in\n"
    			print "   -h, --help            print help\n"
    			print "   -i, --ignore          list of files, directories, or types to ignore\n"
    			print "   -m, --max-depth       max depth for recursive directory parsing\n"
    			print "   -p, --push            push/pull issues from remotes\n"
    			print "   -r, --remote          list / create tokens for bitbucket/github\n"
    			print "   -t, --tags            list of tags to search for\n"
    			print "   -v, --version    	 print watson version and info\n"
    			print "\n"

    			print "Any number of files, tags, dirs, and ignores can be listed after flag\n"
    			print "Ignored files should be space separated\n"
    			print "To use *.filetype identifier, encapsulate in \"\" to avoid shell substitutions \n"
    			print "\n"

    			print "Report bugs to: watson\@goosecode.com\n"
    			print "watson home page: <http://goosecode.com/projects/watson>\n"
    			print "[goosecode] labs | 2012-2013\n"
    			#print RESET;
			
			    return true

			end


			###########################################################
			# version 
			###########################################################
			
			def version
				print "watson v1.0\n"
				print "Copyright (c) 2012-2013 goosecode labs\n"
				print "Licensed under MIT, see LICENSE for details\n"
				print "\n"

				print "Written by nhmood, see <http://goosecode.com/projects/watson>\n"		
				return true
			end


		end
	end
end



