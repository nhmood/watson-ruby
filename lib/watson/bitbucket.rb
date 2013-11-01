module Watson
	class Remote
		class Bitbucket
		# Class constants
		DEBUG = true		# Debug printing for this class

	
		class << self

		# [todo] - Allow closing of issues from watson? Don't like that idea but maybe
		# Include for debug_print
		include Watson
		
		###########################################################
		# setup 
		###########################################################

		def setup(config)
			# Identify method entry
			debug_print "#{self.class} : #{__method__}\n"
		
			@config = config

			print "Obtaining OAuth Token for Bitbucket...\n"
			
			# Check config to make sure no previous API exists
			if ( (@config.bitbucket_api.empty?  == false) || (@config.bitbucket_repo.empty? == false) )

				print "Previous Bitbucket API + Repo is in RC, are you sure you want to overwrite?\n"
				print "(Y)es/(N)o: "

				# Get user input
				_overwrite = $stdin.gets.chomp
				if (_overwrite.downcase == "no" || _overwrite.downcase == "n")
					print "Not overwriting current Bitbucket API + repo info\n"
					return false
				end
			end


			print "Access to your Bitbucket account required to make/update issues\n"
			print "See help or README for more details on GitHub/Bitbucket access\n\n"


			# [todo] - Bitbucket OAuth not implemented yet so warn user about HTTP Auth
			# Bitbucket doesn't have nonOAuth flow that GitHub does :(
			# Even if I use OAuth lib, still need to validate from webview which is lame
			print "Bitbucket OAuth not implemented yet.\n"
			print "Basic HTTP Auth in use, will request PW entry every time.\n\n"


			# Poor mans username/password grabbing
			print "Username: "
			_username = $stdin.gets.chomp
			if (_username.empty?)
				print "Input blank. Please enter your username!\n"
				return false
			end



			# [fix] - Crossplatform password block needed, not sure if current method is safe either
			# Block output to tty to prevent PW showing, Linux/Unix only :(
			print "Password: "
			system "stty -echo"
			_password = $stdin.gets.chomp
			system "stty echo"
			if (_password.empty?)
				print "Input is blank. Please enter your password!\n"
				return false
			else
				print "\n"
			end


			# Get repo information, if blank give error
			print "Repo information required\n"
			print "Please provide owner that repo is under followed by repo\n"
			print "e.g. owner: nhmood, repo: watson (case sensitive)\n"
			print "See help or README for more details on GitHub access\n\n"

			print "Owner: "
			_owner = $stdin.gets.chomp
			if (_owner.empty?)
				print "Input blank. Please enter the owner the repo is under!\n"
				return false
			end

			print "Repo: "
			_repo = $stdin.gets.chomp
			if (_repo.empty?)
				print "Input blank. Please enter the repo name!\n"
				return false
			end


			# HTTP Request to check if Repo exists and user has access 
			# http://confluence.atlassian.com/display/BITBUCKET/Use+the+Bitbucket+REST+APIs 

			# Create options hash to pass to Remote::http_call 
			# Endpoint for accessing Repo as User with SSL 
			# Basic auth with user input
			opts = {:url        => "https://bitbucket.org/api/1.0/repositories/#{_owner}/#{_repo}",
					:ssl        => true,
					:method     => "GET",
					:basic_auth => [_username, _password],
					:verbose    => false
				   }

			_json, _resp  = Watson::Remote.http_call(opts)

			# Check response to validate authorization
			if (_resp.code == "200")
				print "Successfully accessed remote repo with given credentials\n"
			else
				print "Unable to access remote repo with given credentials\n"
				print "Check that credentials are correct and repository exists under user\n"
				print "#{_resp.code} - #{_resp.message}\n"
				return false
			end	

	
			# No OAuth for Bitbucket yet so just store username in api for config
			# This will let us just prompt for PW
			@config.bitbucket_api = _owner
			@config.bitbucket_pw = _password	# Never gets written to file
			@config.bitbucket_repo = _repo
			debug_print " \n"

			# All setup has been completed, need to update RC
			# Call config updater/writer from @config to write config	
			debug_print "Updating config with new Bitbucket info\n"
			@config.update_conf("bitbucket_api", "bitbucket_repo")

			# Give user some info
			print "Bitbucket successfully setup\n"
			print "Issues will now automatically be updated on Bitbucket by default\n"
			print "Use -l, --local to not update against Bitbucket\n"
			print "See help or README for more details on GitHub/Bitbucket access\n"

			return true

		end ########## setup ##########


		###########################################################
		# get_issues 
		###########################################################

		def get_issues(config)
			# Identify method entry
			debug_print "#{self.class} : #{__method__}\n"

			# Only attempt to get issues if API is specified 
			if (config.bitbucket_api.empty?)
				debug_print "No API found, this shouldn't be called...\n"
				return false
			end


			# If we haven't obtained the pw from user yet, do it
			if (config.bitbucket_pw.empty?)
				# No OAuth for Bitbucket yet, gotta get user password in order to make calls :(
				print "Bitbucket password required for remote checking/posting:\n "
				
				# Block output to tty to prevent PW showing, Linux/Unix only :(
				print "Password: "
				system "stty -echo"
				_password = $stdin.gets.chomp
				system "stty echo"
				if (_password.empty?)
					print "Input is blank. Please enter your password!\n"
					return false
				else
					print "\n"
				end

				config.bitbucket_pw = _password
			end


			# Get all open tickets (anything but resolved)
			# Create options hash to pass to Remote::http_call 
			# Issues URL for Bitbucket + SSL
			opts = {:url        => "https://bitbucket.org/api/1.0/repositories/#{config.bitbucket_api}/#{config.bitbucket_repo}/issues?status=!resolved",
					:ssl        => true,
					:method     => "GET",
					:basic_auth => [config.bitbucket_api, config.bitbucket_pw],
					:verbose    => false
				   }

			_json, _resp  = Watson::Remote.http_call(opts)
			
			
			# Check response to validate repo access
			if (_resp.code != "200")
				print " x ", RED
				print " --> Unable to access remote #{config.bitbucket_repo}, Bitbucket settings may be invalid\n"
				print "Make sure you have created an issue tracker for your repository on the Bitbucket website\n"
				print "     Consider running --remote (-r) option to regenerate/validate settings \n\n"
				print "#{_resp.code} - #{_resp.message}\n"

				debug_print "Bitbucket invalid, setting config var\n"
				config.bitbucket_valid = false
				return false
			end

			

			config.bitbucket_issues[:open] = _json["issues"]
			config.bitbucket_valid = true
			
			# Get all closed tickets
			# Create options hash to pass to Remote::http_call 
			# Issues URL for Bitbucket + SSL
			opts = {:url        => "https://bitbucket.org/api/1.0/repositories/#{config.bitbucket_api}/#{config.bitbucket_repo}/issues?status=resolved",
					:ssl        => true,
					:method     => "GET",
					:basic_auth => [config.bitbucket_api, config.bitbucket_pw],
					:verbose    => false 
				   }

			_json, _resp  = Watson::Remote.http_call(opts)

			# Check response to validate repo access
			# Shouldn't be necessary if we passed the last check but just to be safe
			if (_resp.code != "200")
				print " x ", RED
				print " --> Unable to get closed issues. Since the open issues were obtained, something is probably wrong and you should file a bug report or something...\n" 
				print "#{_resp.code} - #{_resp.message}\n"
				
				debug_print "Bitbucket invalid, setting config var\n"
				config.bitbucket_valid = false
				return false
			end

			config.bitbucket_issues[:closed]  = _json["issues"] 
			config.bitbucket_valid = true
			return true
		end ########## get_issues ##########	



		###########################################################
		# post_issues 
		###########################################################
		# [todo] - Better way to identify/compare remote->local issues than md5
		# 		   Current md5 based on some things that easily can change, need better ident

		def post_issue(issue, config)
			# Identify method entry
			debug_print "#{self.class} : #{__method__}\n"
	
				
			# Only attempt to get issues if API is specified 
			if (config.bitbucket_api.empty?)
				debug_print "No API found, this shouldn't be called...\n"
				return false
			end

			# Check that issue hasn't been posted already by comparing md5s
			# Go through all open issues, if there is a match in md5, return out of method
			# [todo] - Play with idea of making body of GitHub issue hash format to be exec'd
			#		   Store pieces in text as :md5 => "whatever" so when we get issues we can
			#		   call exec and turn it into a real hash for parsing in watson
			#		   Makes watson code cleaner but not as readable comment on GitHub...?
			debug_print "Checking open issues to see if already posted\n"
			config.bitbucket_issues[:open].each do | _open | 
				debug_print "Did not find in #{_open["content"]}\n"
				if (_open["content"].include?(issue[:md5]))
					debug_print "Found in #{_open["content"]}, not posting\n"
					return false
				end
			end	
			
			debug_print "Checking closed issues to see if already posted\n"
			config.bitbucket_issues[:closed].each do  | _closed | 
				debug_print "Did not find in #{_closed[:comment]}\n"
				if (_open["body"].include?(issue[:md5]))
					debug_print "Found in #{_closed[:comment]}, not posting\n"
					return false
				end
			end



			# If we haven't obtained the pw from user yet, do it
			if (config.bitbucket_pw.empty?)
				# No OAuth for Bitbucket yet, gotta get user password in order to make calls :(
				print "Bitbucket password required for remote checking/posting: "
				
				# Block output to tty to prevent PW showing, Linux/Unix only :(
				print "Password: "
				system "stty -echo"
				_password = $stdin.gets.chomp
				system "stty echo"
				if (_password.empty?)
					print "Input is blank. Please enter your password!\n"
					return false
				else
					print "\n"
				end

				config.bitbucket_pw = _password
			end



		
			# We didn't find the md5 for this issue in the open or closed issues, so safe to post
		
			# Create the body text for the issue here, too long to fit nicely into opts hash
			# [review] - Only give relative path for privacy when posted
			_body = "__filename__ : #{issue[:path]}  \n" +
					"__line #__ : #{issue[:line_number]}  \n" + 
					"__tag__ : #{issue[:tag]}  \n" +
					"__md5__ : #{issue[:md5]}  \n\n" +
					"#{issue[:context].join}"
			
			# Create option hash to pass to Remote::http_call
			# Issues URL for GitHub + SSL
			# No tag or label concept in Bitbucket unfortunately :(
			opts = {:url        => "https://bitbucket.org/api/1.0/repositories/#{config.bitbucket_api}/#{config.bitbucket_repo}/issues",
					:ssl        => true,
					:method     => "POST",
					:basic_auth => [config.bitbucket_api, config.bitbucket_pw],
					:data		=> [{"title" => issue[:comment],
									"content" => _body }],
					:verbose    => true 
				   }

			_json, _resp  = Watson::Remote.http_call(opts)
		
				
			# Check response to validate repo access
			# Shouldn't be necessary if we passed the last check but just to be safe
			if (_resp.code != "200")
				print " x ", RED
				print " --> Post unsuccessful. Since the open issues were obtained earlier, something is probably wrong and you should let someone know...\n" 
				print "#{_resp.code} - #{_resp.message}\n"
				return false
			end
		
			return true	
		end ########## post_issue ##########	
		
		end ########## class << self ##########



		end ########## class GitHub ##########
	end ########## class Remote ##########
end ########## module Watson ##########
