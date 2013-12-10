module Watson
  class Remote
    # GitLab remote access class
    # Contains all necessary methods to obtain access to, get issue list,
    # and post issues to GitLab
    class GitLab

    # Debug printing for this class
    DEBUG = false

    class << self

    # [todo] - Keep asking for user data until valid instead of leaving app

    # Include for debug_print
    include Watson

    #############################################################################
    # Setup remote access to GitLab
    # Get Username, Repo, and PW and perform necessary HTTP calls to check validity
    def setup(config)

      # Identify method entry
      debug_print "#{ self.class } : #{ __method__ }\n"

      formatter = Printer.new(config).build_formatter
      formatter.print_status "+", GREEN
      print BOLD + "Obtaining OAuth Token for GitLab...\n" + RESET

      # Check config to make sure no previous API exists
      unless config.gitlab_api.empty? && config.gitlab_repo.empty? && config.gitlab_endpoint.empty?
        formatter.print_status "!", RED
        print BOLD + "Previous GitLab API + Repo is in RC, are you sure you want to overwrite?\n" + RESET
        print "      (Y)es/(N)o: "

        # Get user input
        _overwrite = $stdin.gets.chomp
        if ["no", "n"].include?(_overwrite.downcase)
          print "\n\n"
          formatter.print_status "x", RED
          print BOLD + "Not overwriting current GitLab API + repo info\n" + RESET
          return false
        end
      end


      formatter.print_status "!", YELLOW
      print BOLD + "Access to your GitLab account required to make/update issues\n" + RESET
      print "      See help or README for more details on GitHub/Bitbucket/GitLab access\n\n"

      print BOLD + "GitLab API Endpoint: " + RESET
      _endpoint = $stdin.gets.chomp.chomp('/')
      if _endpoint.empty?
        formatter.print_status "x", RED
        print BOLD + "Input blank. Please enter your API endpoint!\n\n" + RESET
        return false
      end
      
      # Make sure we have the http(s)://
      if !_endpoint.match(/(http|https):\/\//)
        _endpoint = "http://#{_endpoint}"
      end
     
       print "\n"

      # GitLab only requires private token to ID, can't get it with basic auth though
      print BOLD + "GitLab Private Token: " + RESET
      _token = $stdin.gets.chomp
      if _token.empty?
        formatter.print_status "x", RED
        print BOLD + "Input blank. Please enter your private token!\n\n" + RESET
        return false
      end

      
      # Get project to be synced against 
      print BOLD + "GitLab Project (ID or Namespace/Name): " + RESET
      _repo = $stdin.gets.chomp
      if _repo.empty?
        formatter.print_status "x", RED
        print BOLD + "Input blank. Please enter project!\n\n" + RESET
        return false
      end

      # Format project to GitLab specs (i.e. if Namespace/Name, need to URL encode /)
      if !_repo.match(/\d+/)
        _repo = URI.escape(_repo, "/") 
      end

      # HTTP Request to make sure we have access to project 
      # GitLab API - http://api.gitlab.org/

      # Create options hash to pass to Remote::http_call
      # Project URL + SSL
      
      opts = {
        :url        => "#{ _endpoint }/api/v3/projects/#{ _repo }",
        :ssl        =>  _endpoint.match(/^https/) ? true : false,
        :method     => "GET",
        :headers    => [ { :field => "PRIVATE-TOKEN", :value => _token } ],
        :verbose    => false
      }

      _json, _resp  = Watson::Remote.http_call(opts)

      # Check response to validate authorization
      if _resp.code == "200"
        formatter.print_status "o", GREEN
        print BOLD + "Succsesfully accessed GitLab with specified settings\n\n" + RESET
      else
        formatter.print_status "x", RED
        print BOLD + "Unable to access GitLab with specified settings\n" + RESET
        print "      Status: #{ _resp.code } - #{ _resp.message }\n\n"
        return false
      end

      # Store endpoint and API key obtained from POST to @config.gitlab_api
      config.gitlab_endpoint = _endpoint
      config.gitlab_api = _token
      config.gitlab_repo = URI.unescape(_repo)    # Unescape for config readability
      debug_print "Config GitLab API Endpoint updated to: #{ config.gitlab_endpoint }\n"
      debug_print "Config GitLab API Key updated to:      #{ config.gitlab_api }\n"
      debug_print "Config GitLab Repo updated to:         #{ config.gitlab_repo }\n"



      # All setup has been completed, need to update RC
      # Call config updater/writer from @config to write config
      debug_print "Updating config with new GitLab info\n"
      config.update_conf("gitlab_api", "gitlab_repo", "gitlab_endpoint")

      # Give user some info
      print "\n"
      formatter.print_status "o", GREEN
      print BOLD + "GitLab successfully setup\n" + RESET
      print "      Issues will now automatically be retrieved from GitLab by default\n"
      print "      Use -u, --update to post issues to GitLab\n"
      print "      See help or README for more details on GitHub/Bitbucket/GitLab access\n\n"

      return true

    end


    ###########################################################
    # Get all remote GitLab issues and store into Config container class
    def get_issues(config)

      # Identify method entry
      debug_print "#{ self.class } : #{ __method__ }\n"

      # Set up formatter for printing errors
      # config.output_format should be set based on less status by now
      formatter = Printer.new(config).build_formatter

      # Only attempt to get issues if API is specified
      if config.gitlab_api.empty?
        debug_print "No API found, this shouldn't be called...\n"
        return false
      end


      # GitLab API doesn't allow you to filter based on state (or anything for that matter...)
      # Grab all the issues and then sort through them based on state

      # Get all issues 
      # Create options hash to pass to Remote::http_call
      # Use URI.escape so config file is readable
      opts = {
        :url        => "#{ config.gitlab_endpoint }/api/v3/projects/#{ URI.escape(config.gitlab_repo, "/") }/issues",
        :ssl        => config.gitlab_endpoint.match(/^https/) ? true : false,
        :method     => "GET",
        :headers    => [ { :field => "PRIVATE-TOKEN", :value => config.gitlab_api } ],
        :verbose    => false
      }

      _json, _resp  = Watson::Remote.http_call(opts)

      # Check response to validate repo access
      if _resp.code != "200"
        formatter.print_status "x", RED
        print BOLD + "Unable to access remote #{ config.gitlab_repo }, GitLab API may be invalid\n" + RESET
        print "      Consider running --remote (-r) option to regenerate key\n\n"
        print "      Status: #{ _resp.code } - #{ _resp.message }\n"

        debug_print "GitLab invalid, setting config var\n"
        config.gitlab_valid = false
        return false
      end



      # Create hash entry from each returned issue
      # MD5 of issue serves as hash key
      # Hash value is another hash of info we will use
      _json.each do |issue|

        _md5 = issue["body"].match(/__md5__ : (\w+)/)[1]

        config.gitlab_issues[_md5] = {
          :title => issue["title"],
          :id    => issue["iid"],
          :state => issue["state"]
        }
      end
    
      config.gitlab_valid = true
    end


    ###########################################################
    # Post given issue to remote GitLab repo
    def post_issue(issue, config)
    # [todo] - Better way to identify/compare remote->local issues than md5
    #        Current md5 based on some things that easily can change, need better ident

      # Identify method entry
      debug_print "#{ self.class } : #{ __method__ }\n"


      # Set up formatter for printing errors
      # config.output_format should be set based on less status by now
      formatter = Printer.new(config).build_formatter


      # Only attempt to get issues if API is specified
      if config.gitlab_api.empty?
        debug_print "No API found, this shouldn't be called...\n"
        return false
      end



      return false if config.gitlab_issues.key?(issue[:md5])
      debug_print "#{issue[:md5]} not found in remote issues, posting\n"


      # We didn't find the md5 for this issue in the open or closed issues, so safe to post

      # Create the body text for the issue here, too long to fit nicely into opts hash
      # [review] - Only give relative path for privacy when posted
      _body =
        "__filename__ : #{ issue[:path] }\n" +
        "__line #__ : #{ issue[:line_number] }\n" +
        "__tag__ : #{ issue[:tag] }\n" +
        "__md5__ : #{ issue[:md5] }\n\n" +
        "#{ issue[:context].join }\n"



      # Create option hash to pass to Remote::http_call
      # Issues URL for GitLab
      opts = {
        :url        => "#{ config.gitlab_endpoint }/api/v3/projects/#{ URI.escape(config.gitlab_repo, "/") }/issues",
        :ssl        => config.gitlab_endpoint.match(/^https/) ? true : false,
        :method     => "POST",
        :headers    => [ { :field => "PRIVATE-TOKEN", :value => config.gitlab_api } ],
        :data       => [{ "title"  => issue[:title] + " [#{ issue[:path] }]",
                         "labels" => "#{issue[:tag]}, watson",
                         "description" => _body }],
        :verbose    => false
      }

      _json, _resp  = Watson::Remote.http_call(opts)


      # Check response to validate repo access
      # Shouldn't be necessary if we passed the last check but just to be safe
      if _resp.code != "201"
        formatter.print_status "x", RED
        print BOLD + "Post unsuccessful. \n" + RESET
        print "      Since the open issues were obtained earlier, something is probably wrong and you should let someone know...\n"
        print "      Status: #{ _resp.code } - #{ _resp.message }\n"
        return false
      end

      # Parse response and append issue hash so we are up to date
      config.gitlab_issues[issue[:md5]] = {
        :title => _json["title"],
        :id    => _json["iid"],
        :state => _json["state"]
      }


      return true
    end

    end
    end
  end
end
