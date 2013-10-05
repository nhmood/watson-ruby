module Watson
	class Remote
		# Class Constants
		DEBUG = true 		# Debug printing for this class
	
	
		class << self
		# Include for debug_print
		include Watson

		# Required libs		
		require 'net/https'
		require 'uri'
		require 'json'
			
		###########################################################
		# http_call 
		###########################################################
		
		# [review] - Don't use DEBUG inside Remote class but pull from calling method's class?
		# [review] - Not sure if this is the best/proper way to do things but it works...
		#
		# Options Hash Format
		# :url 		  => string					 --> URL of endpoint
		# :ssl 		  => true/false 		 	 --> Use SSL in connection (HTTPS)
		# :method     => string					 --> GET or POST for respective HTTP method
		# :basic_auth => [username, password] 	 --> Array of username and pw to use for basic authentication
		#											 If empty, assume no user authentication
		# :auth 	  => string					 --> Authentication token 
		# :data 	  => hash					 --> Hash of data to be POST'd in HTTP request
		# :verbose    => true/false				 --> Turn on verbose debug for this call 

			def http_call( opts )
				# Check URL in hash and get URI from it, then set up HTTP connection
				_uri = URI(opts.fetch(:url))  if (opts.fetch(:url, nil) =~ /^#{URI::regexp}$/)
				_http = Net::HTTP.new(_uri.host, _uri.port)
				
				# Print out verbose HTTP request if :verbose is set
				# For hardcore debugging when shit really doesn't work
				_http.set_debug_output $stderr if (opts.fetch(:verbose, nil))
				
				# If SSL is set in hash, set HTTP connection to use SSL 
				_http.use_ssl = true if (opts.fetch(:ssl, nil) == true)

				# Create request based on HTTP method
				# [review] - Not sure if to fail with no method or default to GET?
				case opts.fetch(:method, nil).upcase
				when "GET"
					_req = Net::HTTP::Get.new(_uri.request_uri)
			
				when "POST"
					_req = Net::HTTP::Post.new(_uri.request_uri)
				
				else
					debug_print "No method specified, cannot make HTTP request\n"
					return false
				end

				# Check for basic authentication key in hash
				if ( opts.fetch(:basic_auth, nil) && opts.fetch(:basic_auth).size == 2 )
					_req.basic_auth(opts.fetch(:basic_auth)[0], opts.fetch(:basic_auth)[1])
				end

				# Check for Authentication token key in hash to be used in header
				# I think this is pretty universal, but specifically works for GitHub
				if ( opts.fetch(:auth, nil) )
					_req["Authorization"] = "token #{opts.fetch(:auth)}"
				end

				# If a POST method, :data is present, and is a Hash, fill request body with data
				if ( opts.fetch(:method).upcase == "POST" && opts.fetch(:data, nil) && opts.fetch(:data).is_a?(Hash) )
					_req.body = opts.fetch(:data).to_json
				end

				# Make HTTP request
				_resp = _http.request(_req)

				# Debug prints for status and message
				debug_print "HTTP Response Code: #{_resp.code}\n"
				debug_print "HTTP Response  Msg: #{_resp.message}\n"

				_json = JSON.parse(_resp.body)
				debug_print "JSON: \n #{_json}\n"

				# [review] - Returning hash of json + response the right thing to do?
				# return {:json => _json, :resp => _resp}
				return _json, _resp 
			end
		end
	end
end
