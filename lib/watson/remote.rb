module Watson
	# Remote class that handles all remote HTTP calls to Bitbucket and GitHub	
	class Remote

		# Debug printing for this class
		DEBUG = false 		
	
		class << self
		
		# Include for debug_print
		include Watson

		# Required libs		
		require 'net/https'
		require 'uri'
		require 'json'
	
	
		# Default options hash for http_call
		# Will get merged with input argument hash to maintain defaults	
		HTTP_opts = {
	  	  :url 		  => nil,			#--> URL of endpoint [String]
	   	  :ssl		  => false,			#--> Use SSL in connection (HTTPS) (True/False]
	 	  :method 	  => nil,			#--> GET or POST for respective HTTP method [String]
	  	  :basic_auth => Array.new(0),	#--> Array of username and pw to use for basic authentication
                                		#    If empty, assume no user authentication [Array]
		  :auth 	  => nil,			#--> Authentication token [String]
		  :data 	  => nil,			#--> Hash of data to be POST'd in HTTP request [Hash]
		  :verbose    => false			#--> Turn on verbose debug for this call [True/False]
		}
			
		###########################################################
		# Generic HTTP call method
		# Accepts input hash of options that dictate how the HTTP call is to be made 
		def http_call( opts )
		# [review] - Don't use DEBUG inside Remote class but pull from calling method's class?
		# [review] - Not sure if this is the best/proper way to do things but it works...

			# Identify method entry
			debug_print "#{ self.class } : #{ __method__ }\n"
			
			# Merge default options with those passed in by user to form complete opt list
			opts = HTTP_opts.merge(opts)


			# Check URL in hash and get URI from it, then set up HTTP connection
			if opts[:url] =~ /^#{URI::regexp}$/
				_uri = URI(opts[:url]) 
			else
				debug_print "No URL specified in input opts, exiting HTTP call\n"
				return false
			end
			
			_http = Net::HTTP.new(_uri.host, _uri.port)
			
			# Print out verbose HTTP request if :verbose is set
			# For hardcore debugging when shit really doesn't work
			_http.set_debug_output $stderr if opts[:verbose] == true
			
			# If SSL is set in hash, set HTTP connection to use SSL 
			_http.use_ssl = true if opts[:ssl] == true

			# Create request based on HTTP method
			# [review] - Not sure if to fail with no method or default to GET?
			case opts[:method].upcase
			when "GET"
				_req = Net::HTTP::Get.new(_uri.request_uri)
		
			when "POST"
				_req = Net::HTTP::Post.new(_uri.request_uri)
			
			else
				debug_print "No method specified, cannot make HTTP request\n"
				return false
			end

			# Check for basic authentication key in hash
			if opts[:basic_auth].size == 2
				_req.basic_auth(opts[:basic_auth][0], opts[:basic_auth][1])
			else
				debug_print "Invalid basic HTTP auth credentials\n"
				return false
			end	

			# Check for Authentication token key in hash to be used in header
			# I think this is pretty universal, but specifically works for GitHub
			if opts[:auth]
				_req["Authorization"] = "token #{ opts[:auth] }"
			end

			# [review] - Add :data_format to use set_form_data vs json body?
			# For now, use Hash or Array, this is to differentiate between 
			# putting post data in body vs putting it in the form
			
			# If a POST method, :data is present, and is a Hash, fill request body with data
			if opts[:method].upcase == "POST" && opts[:data] && opts[:data].is_a?(Hash)
				_req.body = opts[:data].to_json
			end

			# If a POST method, :data is present, and is an Array, use set_form_data
			if opts[:method].upcase == "POST" && opts[:data] && opts[:data].is_a?(Array)
				_req.set_form_data(opts[:data][0])
			end

			# Make HTTP request
			_resp = _http.request(_req)

			# Debug prints for status and message
			debug_print "HTTP Response Code: #{ _resp.code }\n"
			debug_print "HTTP Response  Msg: #{ _resp.message }\n"

			# [fix] - Not sure if 401 is the only code that gives nonparseable body? 
			# Figure out what other response codes are bad news for JSON.parse
			_json = _resp.code == "401" ? Hash.new :  JSON.parse(_resp.body)
			debug_print "JSON: \n #{ _json }\n"

			# [review] - Returning hash of json + response the right thing to do?
			# return {:json => _json, :resp => _resp}
			return _json, _resp 
		end
	end
	end
end
