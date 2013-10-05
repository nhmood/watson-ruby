module Watson
	class Remote
		class GitHub
		# Class constants
		DEBUG = true		# Debug printing for this class

	
		class << self
		# Include for debug_print
		include Watson
		
		###########################################################
		# setup 
		###########################################################

			def setup(config)
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
				# Basic auth with user input
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
			end

		end
		end
	end
end
