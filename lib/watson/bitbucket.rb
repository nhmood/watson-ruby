module Watson
  class Remote
    # Bitbucket remote access class
    # Contains all necessary methods to obtain access to, get issue list,
    # and post issues to Bitbucket
    class Bitbucket

    # Debug printing for this class
    DEBUG = false

    class << self

    # [todo] - Allow closing of issues from watson? Don't like that idea but maybe
    # [todo] - Wrap Bitbucket password grabbing into separate method

    # Include for debug_print
    include Watson

    #############################################################################
    # Setup remote access to Bitbucket
    # Get Username, Repo, and PW and perform necessary HTTP calls to check validity
    def setup(config)

      # Identify method entry
      debug_print "#{ self.class } : #{ __method__ }\n"

      formatter = Printer.new(config).build_formatter
      formatter.print_status "+", GREEN
      print BOLD +  "Attempting to access Bitbucket...\n" + RESET

      # Check config to make sure no previous repo info exists
      unless config.bitbucket_api.empty? && config.bitbucket_repo.empty?
        formatter.print_status "!", RED
        print BOLD + "Previous Bitbucket API + Repo is in RC, are you sure you want to overwrite?\n" + RESET
        print "      (Y)es/(N)o: "

        # Get user input
        _overwrite = $stdin.gets.chomp
        if ["no", "n"].include?(_overwrite.downcase)
          print "\n"
          formatter.print_status "x", RED
          print BOLD + "Not overwriting current Bitbucket API + repo info\n" + RESET
          return false
        end
      end


      formatter.print_status "!", YELLOW
      print BOLD + "Access to your Bitbucket account required to make/update issues\n" + RESET
      print "      See help or README for more details on GitHub/Bitbucket access\n\n"


      # [todo] - Bitbucket OAuth not implemented yet so warn user about HTTP Auth
      # Bitbucket doesn't have nonOAuth flow that GitHub does :(
      # Even if I use OAuth lib, still need to validate from webview which is lame
      formatter.print_status "!", RED
      print BOLD + "Bitbucket OAuth not implemented yet.\n" + RESET;
      print "      Basic HTTP Auth in use, will request PW entry every time.\n\n"


      # [todo] - Don't just check for blank password but invalid as well
      # Poor mans username/password grabbing
      print BOLD + "Username: " + RESET
      _username = $stdin.gets.chomp
      if _username.empty?
        formatter.print_status "x", RED
        print BOLD + "Input blank. Please enter your username!\n\n" + RESET
        return false
      end

      print "\n"

      # Get repo information, if blank give error
      formatter.print_status "!", YELLOW
      print BOLD + "Repo information required\n" + RESET
      print "      Please provide owner that repo is under followed by repo name\n"
      print "      e.g. owner: nhmood, repo: watson (case sensitive)\n"
      print "      See help or README for more details on GitHub access\n\n"

      print BOLD + "Owner: " + RESET
      _owner = $stdin.gets.chomp
      if _owner.empty?
        print "\n"
        formatter.print_status "x", RED
        print BOLD + "Input blank. Please enter the owner the repo is under!\n\n" + RESET
        return false
      end

      print BOLD + "Repo: " + RESET
      _repo = $stdin.gets.chomp
      if _repo.empty?
        print "\n"
        formatter.print_status "x", RED
        print BOLD + "Input blank. Please enter the repo name!\n\n" + RESET
        return false
      end

      print "\n"

      # [fix] - Crossplatform password block needed, not sure if current method is safe either
      # Block output to tty to prevent PW showing, Linux/Unix only :(
      print BOLD + "Password: " + RESET
      system "stty -echo"
      _password = $stdin.gets.chomp
      system "stty echo"
      print "\n"
      if _password.empty?
        formatter.print_status "x", RED
        print BOLD + "Input is blank. Please enter your password!\n\n" + RESET
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
      if _resp.code == "200"
        print "\n"
        formatter.print_status "o", GREEN
        print BOLD + "Successfully accessed remote repo with given credentials\n" + RESET
      else
        print "\n"
        formatter.print_status "x", RED
        print BOLD + "Unable to access /#{ _owner }/#{ _repo } with given credentials\n" + RESET
        print "      Check that credentials are correct and repository exists under user\n"
        print "      Status: #{ _resp.code } - #{ _resp.message }\n\n"
        return false
      end


      # No OAuth for Bitbucket yet so just store username in api for config
      # This will let us just prompt for PW
      config.bitbucket_api = _username
      config.bitbucket_pw = _password # Never gets written to file
      config.bitbucket_repo = "#{ _owner }/#{ _repo }"
      debug_print " \n"

      # All setup has been completed, need to update RC
      # Call config updater/writer from @config to write config
      debug_print "Updating config with new Bitbucket info\n"
      config.update_conf("bitbucket_api", "bitbucket_repo")

      print "\n"
      formatter.print_status "o", GREEN
      print BOLD + "Bitbucket successfully setup\n" + RESET
      print "      Issues will now automatically be retrieved from Bitbucket by default\n"
      print "      Use -p, --push to post issues to GitHub\n"
      print "      See help or README for more details on GitHub/Bitbucket access\n\n"

      return true

    end


    ###########################################################
    # Get all remote Bitbucket issues and store into Config container class
    def get_issues(config)

      # Identify method entry
      debug_print "#{ self.class } : #{ __method__ }\n"


      # Set up formatter for printing errors
      # config.output_format should be set based on less status by now
      formatter = Printer.new(config).build_formatter


      # Only attempt to get issues if API is specified
      if config.bitbucket_api.empty?
        debug_print "No API found, this shouldn't be called...\n"
        return false
      end

      # If we haven't obtained the pw from user yet, do it
      if config.bitbucket_pw.empty?
        # No OAuth for Bitbucket yet, gotta get user password in order to make calls :(
        formatter.print_status "!", YELLOW
        print BOLD + "Bitbucket password required for remote checking/posting.\n" + RESET
        print "      Password: "

        # Block output to tty to prevent PW showing, Linux/Unix only :(
        system "stty -echo"
        _password = $stdin.gets.chomp
        system "stty echo"
        if _password.empty?
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
      opts = {:url        => "https://bitbucket.org/api/1.0/repositories/#{ config.bitbucket_repo }/issues?status=!resolved",
          :ssl        => true,
          :method     => "GET",
          :basic_auth => [config.bitbucket_api, config.bitbucket_pw],
          :verbose    => false
           }

      _json, _resp  = Watson::Remote.http_call(opts)


      # Check response to validate repo access
      if _resp.code != "200"
        formatter.print_status "x", RED
        print BOLD + "Unable to access remote #{ config.bitbucket_repo }, Bitbucket API may be invalid\n" + RESET
        print "      Make sure you have created an issue tracker for your repository on the Bitbucket website\n"
        print "      Consider running --remote (-r) option to regenerate/validate settings\n"
        print "      Status: #{ _resp.code } - #{ _resp.message }\n\n"

        debug_print "Bitbucket invalid, setting config var\n"
        config.bitbucket_valid = false
        return false
      end



      config.bitbucket_issues[:open] = _json["issues"].empty? ? Hash.new : _json["issues"]
      config.bitbucket_valid = true

      # Get all closed tickets
      # Create options hash to pass to Remote::http_call
      # Issues URL for Bitbucket + SSL
      opts = {:url        => "https://bitbucket.org/api/1.0/repositories/#{ config.bitbucket_repo }/issues?status=resolved",
          :ssl        => true,
          :method     => "GET",
          :basic_auth => [config.bitbucket_api, config.bitbucket_pw],
          :verbose    => false
           }

      _json, _resp  = Watson::Remote.http_call(opts)

      # Check response to validate repo access
      # Shouldn't be necessary if we passed the last check but just to be safe
      if _resp.code != "200"
        formatter.print_status "x", RED
        print BOLD + "Unable to get closed issues.\n" + RESET
        print "      Since the open issues were obtained, something is probably wrong and you should file a bug report or something...\n"
        print "      Status: #{ _resp.code } - #{ _resp.message }\n"

        debug_print "Bitbucket invalid, setting config var\n"
        config.bitbucket_valid = false
        return false
      end

      config.bitbucket_issues[:closed] = _json["issues"].empty? ? Hash.new : _json["issues"]
      config.bitbucket_valid = true
      return true
    end


    ###########################################################
    # Post given issue to remote Bitbucket repo
    def post_issue(issue, config)
    # [todo] - Better way to identify/compare remote->local issues than md5
    #        Current md5 based on some things that easily can change, need better ident

      # Identify method entry
      debug_print "#{self.class} : #{__method__}\n"


      # Set up formatter for printing errors
      # config.output_format should be set based on less status by now
      formatter = Printer.new(config).build_formatter


      # Only attempt to get issues if API is specified
      if config.bitbucket_api.empty?
        debug_print "No API found, this shouldn't be called...\n"
        return false
      end

      # Check that issue hasn't been posted already by comparing md5s
      # Go through all open issues, if there is a match in md5, return out of method
      # [todo] - Play with idea of making body of GitHub issue hash format to be exec'd
      #      Store pieces in text as :md5 => "whatever" so when we get issues we can
      #      call exec and turn it into a real hash for parsing in watson
      #      Makes watson code cleaner but not as readable comment on GitHub...?
      debug_print "Checking open issues to see if already posted\n"
      config.bitbucket_issues[:open].each do | _open |
        if _open["content"].include?(issue[:md5])
          debug_print "Found in #{ _open["title"] }, not posting\n"
          return false
        end
        debug_print "Did not find in #{_open["title"]}\n"
      end

      debug_print "Checking closed issues to see if already posted\n"
      config.bitbucket_issues[:closed].each do  | _closed |
        if _closed["content"].include?(issue[:md5])
          debug_print "Found in #{ _closed["title"] }, not posting\n"
          return false
        end
        debug_print "Did not find in #{ _closed["title"] }\n"
      end


      # If we haven't obtained the pw from user yet, do it
      if config.bitbucket_pw.empty?
        # No OAuth for Bitbucket yet, gotta get user password in order to make calls :(
        formatter.print_status "!", YELLOW
        print BOLD + "Bitbucket password required for remote checking/posting.\n" + RESET
        print "      Password: "

        # Block output to tty to prevent PW showing, Linux/Unix only :(
        print "Password: "
        system "stty -echo"
        _password = $stdin.gets.chomp
        system "stty echo"
        if _password.empty?
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
      _body = "__filename__ : #{ issue[:path] }  \n" +
          "__line #__ : #{ issue[:line_number] }  \n" +
          "__tag__ : #{ issue[:tag] }  \n" +
          "__md5__ : #{ issue[:md5] }  \n\n" +
          "#{ issue[:context].join }"

      # Create option hash to pass to Remote::http_call
      # Issues URL for GitHub + SSL
      # No tag or label concept in Bitbucket unfortunately :(
      opts = {:url        => "https://bitbucket.org/api/1.0/repositories/#{ config.bitbucket_repo }/issues",
          :ssl        => true,
          :method     => "POST",
          :basic_auth => [config.bitbucket_api, config.bitbucket_pw],
          :data   => [{"title" => issue[:title] + " [#{ issue[:path] }]",
                  "content" => _body }],
          :verbose    => false
           }

      _json, _resp  = Watson::Remote.http_call(opts)


      # Check response to validate repo access
      # Shouldn't be necessary if we passed the last check but just to be safe
      if _resp.code != "200"
        formatter.print_status "x", RED
        print BOLD + "Post unsuccessful. \n" + RESET
        print "      Since the open issues were obtained earlier, something is probably wrong and you should let someone know...\n"
        print "      Status: #{ _resp.code } - #{ _resp.message }\n"
        return false
      end

      return true
    end

    end


    end
  end
end
