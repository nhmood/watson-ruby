module Watson
	class Remote
		class GitHub
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

			print "Obtaining OAuth Token for GitHub...\n"
			
			# Check config to make sure no previous API exists
			if ( (@config.github_api.empty?  == false) || (@config.github_repo.empty? == false) )

				print "Previous GitHub API + Repo is in RC, are you sure you want to overwrite?\n"
				print "(Y)es/(N)o: "

				# Get user input
				_overwrite = $stdin.gets.chomp
				if (_overwrite.downcase == "no" || _overwrite.downcase == "n")
					print "Not overwriting current GitHub API + repo info\n"
					return false
				end
			end


			print "Access to your GitHub account required to make/update issues\n"
			print "See help or README for more details on GitHub/Bitbucket access\n\n"

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

			# HTTP Request to get OAuth Token
			# GitHub API v3 - http://developer.github.com/v3/

			# Create options hash to pass to Remote::http_call 
			# Auth URL for GitHub + SSL
			# Repo scope + notes for watson
			# Basic auth with user input
			opts = {:url        => "https://api.github.com/authorizations",
					:ssl        => true,
					:method     => "POST",
					:basic_auth => [_username, _password],
					:data       => {"scopes" => ["repo"], 
			 				        "note" => "watson", 
							        "note_url" => "http://watson.goosecode.com/" }, 
					:verbose    => false
				   }

			_json, _resp  = Watson::Remote.http_call(opts)

			# Check response to validate authorization
			if (_resp.code == "201")
				print "Obtained OAuth Token\n"
			else
				print "Unable to obtain OAuth Token\n"
				print "#{_resp.code} - #{_resp.message}\n"
				return false
			end	
	
			# Store API key obtained from POST to @config.github_api
			@config.github_api = _json["token"]
			debug_print "Config GitHub API Key updated to: #{@config.github_api}\n"



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


			# Make call to GitHub API to create new label for Issues
			# If status returns not 404, then we have access to repo (+ it exists)
			# If 422, then (most likely) the label already exists
		
			# Create options hash to pass to Remote::http_call 
			# Label URL for GitHub + SSL
			#  
			# Auth token
			opts = {:url        => "https://api.github.com/repos/#{_owner}/#{_repo}/labels",
					:ssl        => true,
					:method     => "POST",
					:auth		=> @config.github_api, 
					:data       => {"name" => "watson", 
							        "color" => "00AEEF" }, 
					:verbose    => false
				   }

			_json, _resp  = Watson::Remote.http_call(opts)
		
			# [review] - This is pretty messy, maybe clean it up later	
			# Check response to validate repo access
			if (_resp.code == "404")
				print "Unable to access /#{_owner}/#{_repo}\n"
				print "#{_resp.code} - #{_resp.message}\n"
				return false

			else
				# If it is anything but a 404, I THINK it means we have access...
				# Will assume that until proven otherwise
				print "Repo successfully accessed\n"
				
				# Store owner/repo obtained from POST to @config.github_repo
				@config.github_repo = "#{_owner}/#{_repo}"
				debug_print "Config GitHub API Key updated to: #{@config.github_repo}\n"

				# We already created the label but let's just pretend like we didn't yet...
				print "Creating label for watson on GitHub...\n"
				if (_resp.code == "201")
					print "Label successfully created\n"
				elsif (_resp.code == "422" && _json["code"] = "already_exists")
					print "Label already exists\n"
					print "#{_resp.code} - #{_resp.message}\n"
				else
					print "Unable to create label for /#{_owner}/#{_repo}\n"
					print "#{_resp.code} - #{_resp.message}\n"
				end
			end
	

			# All setup has been completed, need to update RC
			# Call config updater/writer from @config to write config	
			debug_print "Updating config with new GitHub info\n"
			@config.update_conf("github_api", "github_repo")

			# Give user some info
			print "GitHub successfully setup\n"
			print "Issues will now automatically be updated on GitHub by default\n"
			print "Use -l, --local to not update against GitHub\n"
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
			if (config.github_api.empty?)
				debug_print "No API found, this shouldn't be called...\n"
				return false
			end


			# Get all open tickets
			# Create options hash to pass to Remote::http_call 
			# Issues URL for GitHub + SSL
			opts = {:url        => "https://api.github.com/repos/#{config.github_repo}/issues?labels=watson&state=open",
					:ssl        => true,
					:method     => "GET",
					:auth		=> config.github_api, 
					:verbose    => false 
				   }

			_json, _resp  = Watson::Remote.http_call(opts)
			
			
			# Check response to validate repo access
			if (_resp.code != "200")
				print " x ", RED
				print " --> Unable to access remote #{config.github_repo}, GitHub API may be invalid\n"
				print "     Consider running --remote (-r) option to regenerate key\n\n"
				print "#{_resp.code} - #{_resp.message}\n"

				debug_print "GitHub invalid, setting config var\n"
				config.github_valid = false
				return false
			end

			config.github_issues[:open] = _json
			config.github_valid = true
			
			# Get all closed tickets
			# Create option hash to pass to Remote::http_call
			# Issues URL for GitHub + SSL
			opts = {:url        => "https://api.github.com/repos/#{config.github_repo}/issues?labels=watson&state=closed",
					:ssl        => true,
					:method     => "GET",
					:auth		=> config.github_api, 
					:verbose    => false 
				   }

			_json, _resp  = Watson::Remote.http_call(opts)

			# Check response to validate repo access
			# Shouldn't be necessary if we passed the last check but just to be safe
			if (_resp.code != "200")
				print " x ", RED
				print " --> Unable to get closed issues. Since the open issues were obtained, something is probably wrong and you should let someone know...\n" 
				print "#{_resp.code} - #{_resp.message}\n"
				
				debug_print "GitHub invalid, setting config var\n"
				config.github_valid = false
				return false
			end

			config.github_issues[:closed]  = _json
			config.github_valid = true
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
			if (config.github_api.empty?)
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
			config.github_issues[:open].each do | _open | 
				debug_print "Did not find in #{_open[:comment]}\n"
				if (_open["body"].include?(issue[:md5]))
					debug_print "Found in #{_open[:comment]}, not posting\n"
					return false
				end
			end	
			
			
			debug_print "Checking closed issues to see if already posted\n"
			config.github_issues[:closed].each do  | _closed | 
				debug_print "Did not find in #{_closed[:comment]}\n"
				if (_open["body"].include?(issue[:md5]))
					debug_print "Found in #{_closed[:comment]}, not posting\n"
					return false
				end
			end
		
			# We didn't find the md5 for this issue in the open or closed issues, so safe to post
		
			# Create the body text for the issue here, too long to fit nicely into opts hash
			# [review] - Only give relative path for privacy when posted
			_body = "__filename__ : #{issue[:path]}\n" +
					"__line #__ : #{issue[:line_number]}\n" + 
					"__tag__ : #{issue[:tag]}\n" +
					"__md5__ : #{issue[:md5]}\n\n" +
					"#{issue[:context].join}\n"
			
			# Create option hash to pass to Remote::http_call
			# Issues URL for GitHub + SSL
			opts = {:url        => "https://api.github.com/repos/#{config.github_repo}/issues",
					:ssl        => true,
					:method     => "POST",
					:auth		=> config.github_api, 
					:data		=> { "title" => issue[:comment],
									 "labels" => [issue[:tag], "watson"],
									 "body" => _body },
					:verbose    => true 
				   }

			_json, _resp  = Watson::Remote.http_call(opts)
		
				
			# Check response to validate repo access
			# Shouldn't be necessary if we passed the last check but just to be safe
			if (_resp.code != "201")
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
