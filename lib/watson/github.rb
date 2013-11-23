module Watson
  class Remote
    # GitHub remote access class
    # Contains all necessary methods to obtain access to, get issue list,
    # and post issues to GitHub
    class GitHub

    # Debug printing for this class
    DEBUG = false

    class << self

    # [todo] - Allow closing of issues from watson? Don't like that idea but maybe
    # [review] - Properly scope Printer class so we dont need the Printer. for
    #      method calls?
    # [todo] - Keep asking for user data until valid instead of leaving app


    # Include for debug_print
    include Watson

    #############################################################################
    # Setup remote access to GitHub
    # Get Username, Repo, and PW and perform necessary HTTP calls to check validity
    def setup(config)

      # Identify method entry
      debug_print "#{ self.class } : #{ __method__ }\n"

      Printer.print_status "+", GREEN
      print BOLD + "Obtaining OAuth Token for GitHub...\n" + RESET

      # Check config to make sure no previous API exists
      unless config.github_api.empty? && config.github_repo.empty?
        Printer.print_status "!", RED
        print BOLD + "Previous GitHub API + Repo is in RC, are you sure you want to overwrite?\n" + RESET
        print "      (Y)es/(N)o: "

        # Get user input
        _overwrite = $stdin.gets.chomp
        if ["no", "n"].include?(_overwrite.downcase)
          print "\n"
          Printer.print_status "x", RED
          print BOLD + "Not overwriting current GitHub API + repo info\n" + RESET
          return false
        end
      end


      Printer.print_status "!", YELLOW
      print BOLD + "Access to your GitHub account required to make/update issues\n" + RESET
      print "      See help or README for more details on GitHub/Bitbucket access\n\n"


      # [todo] - Don't just check for blank password but invalid as well
      # Poor mans username/password grabbing
      print BOLD + "Username: " + RESET
      _username = $stdin.gets.chomp
      if _username.empty?
        Printer.print_status "x", RED
        print BOLD + "Input blank. Please enter your username!\n\n" + RESET
        return false
      end

      # [fix] - Crossplatform password block needed, not sure if current method is safe either
      # Block output to tty to prevent PW showing, Linux/Unix only :(
      print BOLD + "Password: " + RESET
      system "stty -echo"
      _password = $stdin.gets.chomp
      system "stty echo"
      print "\n\n"
      if _password.empty?
        Printer.print_status "x", RED
        print BOLD + "Input is blank. Please enter your password!\n\n" + RESET
        return false
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
      if _resp.code == "201"
        Printer.print_status "o", GREEN
        print BOLD + "Obtained OAuth Token\n\n" + RESET
      else
        Printer.print_status "x", RED
        print BOLD + "Unable to obtain OAuth Token\n" + RESET
        print "      Status: #{ _resp.code } - #{ _resp.message }\n\n"
        return false
      end

      # Store API key obtained from POST to @config.github_api
      config.github_api = _json["token"]
      debug_print "Config GitHub API Key updated to: #{ config.github_api }\n"


      # Get repo information, if blank give error
      Printer.print_status "!", YELLOW
      print BOLD + "Repo information required\n" + RESET
      print "      Please provide owner that repo is under followed by repo name\n"
      print "      e.g. owner: nhmood, repo: watson (case sensitive)\n"
      print "      See help or README for more details on GitHub access\n\n"

      print BOLD + "Owner: " + RESET
      _owner = $stdin.gets.chomp
      if _owner.empty?
        print "\n"
        Printer.print_status "x", RED
        print BOLD + "Input blank. Please enter the owner the repo is under!\n\n" + RESET
        return false
      end

      print BOLD + "Repo: " + RESET
      _repo = $stdin.gets.chomp
      if _repo.empty?
        print "\n"
        Printer.print_status "x", RED
        print BOLD + "Input blank. Please enter the repo name!\n\n" + RESET
        return false
      end


      # Make call to GitHub API to create new label for Issues
      # If status returns not 404, then we have access to repo (+ it exists)
      # If 422, then (most likely) the label already exists

      # Create options hash to pass to Remote::http_call
      # Label URL for GitHub + SSL
      #
      # Auth token
      opts = {:url        => "https://api.github.com/repos/#{ _owner }/#{ _repo }/labels",
          :ssl        => true,
          :method     => "POST",
          :auth   => config.github_api,
          :data       => {"name" => "watson",
                      "color" => "00AEEF" },
          :verbose    => false
           }

      _json, _resp  = Watson::Remote.http_call(opts)

      # [review] - This is pretty messy, maybe clean it up later
      # Check response to validate repo access
      if _resp.code == "404"
        print "\n"
        Printer.print_status "x", RED
        print BOLD + "Unable to access /#{ _owner }/#{ _repo } with given credentials\n" + RESET
        print "      Check that credentials are correct and repository exists under user\n"
        print "      Status: #{ _resp.code } - #{ _resp.message }\n\n"
        return false

      else
        # If it is anything but a 404, I THINK it means we have access...
        # Will assume that until proven otherwise
        print "\n"
        Printer.print_status "o", GREEN
        print BOLD + "Repo successfully accessed\n\n" + RESET
      end

      # Store owner/repo obtained from POST to @config.github_repo
      config.github_repo = "#{ _owner }/#{ _repo }"
      debug_print "Config GitHub API Key updated to: #{ config.github_repo }\n"

      # Inform user of label creation status (created above)
      Printer.print_status "+", GREEN
      print BOLD + "Creating label for watson on GitHub...\n" + RESET
      if _resp.code == "201"
        Printer.print_status "+", GREEN
        print BOLD + "Label successfully created\n" + RESET
      elsif _resp.code == "422" && _json["code"] == "already_exists"
        Printer.print_status "!", YELLOW
        print BOLD + "Label already exists\n" + RESET
      else
        Printer.print_status "x", RED
        print BOLD + "Unable to create label for /#{ _owner }/#{ _repo }\n" + RESET
        print "      Status: #{ _resp.code } - #{ _resp.message }\n"
      end

      # All setup has been completed, need to update RC
      # Call config updater/writer from @config to write config
      debug_print "Updating config with new GitHub info\n"
      config.update_conf("github_api", "github_repo")

      # Give user some info
      print "\n"
      Printer.print_status "o", GREEN
      print BOLD + "GitHub successfully setup\n" + RESET
      print "      Issues will now automatically be retrieved from GitHub by default\n"
      print "      Use -p, --push to post issues to GitHub\n"
      print "      See help or README for more details on GitHub/Bitbucket access\n\n"

      return true

    end


    ###########################################################
    # Get all remote GitHub issues and store into Config container class

    def get_issues(config)

      # Identify method entry
      debug_print "#{ self.class } : #{ __method__ }\n"

      # Only attempt to get issues if API is specified
      if config.github_api.empty?
        debug_print "No API found, this shouldn't be called...\n"
        return false
      end


      # Get all open tickets
      # Create options hash to pass to Remote::http_call
      # Issues URL for GitHub + SSL
      opts = {:url        => "https://api.github.com/repos/#{ config.github_repo }/issues?labels=watson&state=open",
          :ssl        => true,
          :method     => "GET",
          :auth   => config.github_api,
          :verbose    => false
           }

      _json, _resp  = Watson::Remote.http_call(opts)


      # Check response to validate repo access
      if _resp.code != "200"
        Printer.print_status "x", RED
        print BOLD + "Unable to access remote #{ config.github_repo }, GitHub API may be invalid\n" + RESET
        print "      Consider running --remote (-r) option to regenerate key\n\n"
        print "      Status: #{ _resp.code } - #{ _resp.message }\n"

        debug_print "GitHub invalid, setting config var\n"
        config.github_valid = false
        return false
      end

      config.github_issues[:open] = _json.empty? ? Hash.new : _json
      config.github_valid = true

      # Get all closed tickets
      # Create option hash to pass to Remote::http_call
      # Issues URL for GitHub + SSL
      opts = {:url        => "https://api.github.com/repos/#{ config.github_repo }/issues?labels=watson&state=closed",
          :ssl        => true,
          :method     => "GET",
          :auth   => config.github_api,
          :verbose    => false
           }

      _json, _resp  = Watson::Remote.http_call(opts)

      # Check response to validate repo access
      # Shouldn't be necessary if we passed the last check but just to be safe
      if _resp.code != "200"
        Printer.print_status "x", RED
        print BOLD + "Unable to get closed issues.\n" + RESET
        print "      Since the open issues were obtained, something is probably wrong and you should file a bug report or something...\n"
        print "      Status: #{ _resp.code } - #{ _resp.message }\n"

        debug_print "GitHub invalid, setting config var\n"
        config.github_valid = false
        return false
      end

      config.github_issues[:closed] = _json.empty? ? Hash.new : _json
      config.github_valid = true
      return true
    end


    ###########################################################
    # Post given issue to remote GitHub repo
    def post_issue(issue, config)
    # [todo] - Better way to identify/compare remote->local issues than md5
    #        Current md5 based on some things that easily can change, need better ident

      # Identify method entry
      debug_print "#{ self.class } : #{ __method__ }\n"


      # Only attempt to get issues if API is specified
      if config.github_api.empty?
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
      config.github_issues[:open].each do | _open |
        if _open["body"].include?(issue[:md5])
          debug_print "Found in #{ _open["title"] }, not posting\n"
          return false
        end
        debug_print "Did not find in #{ _open["title"] }\n"
      end


      debug_print "Checking closed issues to see if already posted\n"
      config.github_issues[:closed].each do  | _closed |
        if _closed["body"].include?(issue[:md5])
          debug_print "Found in #{ _closed["title"] }, not posting\n"
          return false
        end
        debug_print "Did not find in #{ _closed["title"] }\n"
      end

      # We didn't find the md5 for this issue in the open or closed issues, so safe to post

      # Create the body text for the issue here, too long to fit nicely into opts hash
      # [review] - Only give relative path for privacy when posted
      _body = "__filename__ : #{ issue[:path] }\n" +
          "__line #__ : #{ issue[:line_number] }\n" +
          "__tag__ : #{ issue[:tag] }\n" +
          "__md5__ : #{ issue[:md5] }\n\n" +
          "#{ issue[:context].join }\n"

      # Create option hash to pass to Remote::http_call
      # Issues URL for GitHub + SSL
      opts = {:url        => "https://api.github.com/repos/#{ config.github_repo }/issues",
          :ssl        => true,
          :method     => "POST",
          :auth   => config.github_api,
          :data   => { "title" => issue[:title] + " [#{ issue[:path] }]",
                   "labels" => [issue[:tag], "watson"],
                   "body" => _body },
          :verbose    => false
           }

      _json, _resp  = Watson::Remote.http_call(opts)


      # Check response to validate repo access
      # Shouldn't be necessary if we passed the last check but just to be safe
      if _resp.code != "201"
        Printer.print_status "x", RED
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
