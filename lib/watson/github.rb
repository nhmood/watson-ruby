module Watson
	class Remote
	require 'net/https'
	require 'uri'
	require 'json'

		class GitHub
		DEBUG = true

	
		class << self
		include Watson
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

				# HTTP Request to get OAuth Token, returns JSON
				# [review] - Not sure if this is the best/proper way to do things but it works...
				# [todo] - Similar HTTP calls used multiple times, abstract into Watson::Remote

				# GitHub API v3 - http://developer.github.com/v3/

				# Set up the HTTP connection
				_uri = URI("https://api.github.com/authorizations")
				_http = Net::HTTP.new(_uri.host, _uri.port)
				_http.use_ssl = true

				# Print out verbose HTTP request 
				# For hardcore debugging when shit really doesn't work uncomment below
				#_http.set_debug_output $stderr 
			
				# Set up the POST request with Basic Auth + Authorization Info for GitHub
				_req = Net::HTTP::Post.new(_uri.request_uri)
				_req.basic_auth(_username, _password)
				_req.body = {"scopes" => ["repo"], 
							 "note" => "watson", 
							 "note_url" => "http://watson.goosecode.com/" }.to_json

				# Make request
				_resp = _http.request(_req)

				# Debug prints for status and message
				debug_print "HTTP Response Code: #{_resp.code}\n"
				debug_print "HTTP Response Msg:  #{_resp.message}\n"

				_json = JSON.parse(_resp.body)
				debug_print "JSON: \n #{_json}\n"

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
				
				# Set up the HTTP connection
				_uri = URI("https://api.github.com/repos/#{_owner}/#{_repo}/labels")
				_http = Net::HTTP.new(_uri.host, _uri.port)
				_http.use_ssl = true
				
				# Print out verbose HTTP request 
				# For hardcore debugging when shit really doesn't work uncomment below
				#_http.set_debug_output $stderr 

				
				# Set up the POST request with Auth token + label info 
				_req = Net::HTTP::Post.new(_uri.request_uri)
				_req["Authorization"] = "token #{@config.github_api}"
				_req.body = {"name" => "watson", 
							 "color" => "00AEEF"}.to_json
			
				# Make request
				_resp = _http.request(_req)

				# Debug prints for status and message
				debug_print "HTTP Response Code: #{_resp.code}\n"
				debug_print "HTTP Response Msg:  #{_resp.message}\n"

				_json = JSON.parse(_resp.body)
				debug_print "JSON: \n #{_json}\n"
				
		
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
				#@config.update_conf("github_api", "github_repo")

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
