module Watson
  class Remote
    # GitHub remote access class
    # Contains all necessary methods to obtain access to, get issue list,
    # and post issues to GitHub
    class GitHub

    class << self

    # [todo] - Allow closing of issues from watson? Don't like that idea but maybe
    # [review] - Properly scope formatter class so we dont need the formatter. for
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

      formatter = Printer.new(config).build_formatter
      formatter.print_status "+", GREEN
      print BOLD + "Obtaining OAuth Token for GitHub...\n" + RESET

      # Create new RC for $HOME/.watsonrc and check for existing remotes there
      _home_conf = Watson::Config.home_conf

      # Check config to make sure no previous API exists
      unless _home_conf.github_api.empty? && config.github_repo.empty? && config.github_endpoint.empty?
        formatter.print_status "!", RED
        print BOLD + "Previous GitHub API + Repo is in RC, are you sure you want to overwrite?\n" + RESET
        print "      (Y)es/(N)o: "

        # Get user input
        _overwrite = $stdin.gets.chomp
        if ["no", "n"].include?(_overwrite.downcase)
          print "\n\n"
          formatter.print_status "x", RED
          print BOLD + "Not overwriting current GitHub API + repo info\n" + RESET
          return false
        end
      end


      formatter.print_status "!", YELLOW
      print BOLD + "Access to your GitHub account required to make/update issues\n" + RESET
      print "      See help or README for more details on GitHub/Bitbucket access\n\n"

      formatter.print_status "!", GREEN
      print BOLD + "Is this a GitHub Enterprise account?\n" + RESET
      print "      (Y)es/(N)o: "

      # Get user input
      _enterprise = $stdin.gets.chomp
      if ["yes", "y"].include?(_enterprise.downcase)
        print "\n\n"
        print BOLD + "GitHub API Endpoint: " + RESET
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

      else
        _endpoint = ''
      end

      print "\n"

      # [todo] - Don't just check for blank password but invalid as well
      # Poor mans username/password grabbing
      print BOLD + "Username: " + RESET
      _username = $stdin.gets.chomp
      if _username.empty?
        formatter.print_status "x", RED
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
        formatter.print_status "x", RED
        print BOLD + "Input is blank. Please enter your password!\n\n" + RESET
        return false
      end

      # Label for Auth Token
      print BOLD + "Auth Token Label (leave blank to ignore): " + RESET
      _label = $stdin.gets.chomp

      _endpoint = "https://api.github.com" if _endpoint.empty?

      # HTTP Request to get OAuth Token
      # GitHub API v3 - http://developer.github.com/v3/

      # Create options hash to pass to Remote::http_call
      # Auth URL for GitHub + SSL
      # Repo scope + notes for watson
      # Basic auth with user input
      opts = {
        :url        => "#{ _endpoint }/authorizations",
        :ssl        => true,
        :method     => "POST",
        :basic_auth => [_username, _password],
        :data       => {"scopes" => ["repo"],
                        "note" => "watson - #{_label}",
                        "note_url" => "http://watson.goosecode.com/" },
        :verbose    => false
      }

      _json, _resp  = Watson::Remote.http_call(opts)

      # Check response to validate authorization
      if _resp.code == "201"
        formatter.print_status "o", GREEN
        print BOLD + "Obtained OAuth Token\n\n" + RESET

      elsif _resp.code == "401"
        begin
          # [todo] - Refactor all
          _json, _resp = two_factor_authentication(opts, formatter)
        rescue => e
          return false
        end
      else
        formatter.print_status "x", RED
        print BOLD + "Unable to obtain OAuth Token\n" + RESET
        print "      Status: #{ _resp.code } - #{ _resp.message }\n\n"
        return false
      end

      # Add to $HOME/.watsonrc and current .watsonrc
      _home_conf.github_api[_username] = _json["token"]
      _home_conf.update_conf("github_api")

      # Store endpoint and API key obtained from POST to @config.github_api
      config.github_endpoint = _endpoint
      config.github_api = {_username => _json["token"]}
      debug_print "Config GitHub API Endpoint updated to: #{ config.github_endpoint }\n"
      debug_print "Config GitHub API Key updated to:      #{ config.github_api }\n"


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


      # Make call to GitHub API to create new label for Issues
      # If status returns not 404, then we have access to repo (+ it exists)
      # If 422, then (most likely) the label already exists

      # Create options hash to pass to Remote::http_call
      # Label URL for GitHub + SSL
      #
      # Auth token
      opts = {
        :url        => "#{ _endpoint }/repos/#{ _owner }/#{ _repo }/labels",
        :ssl        => true,
        :method     => "POST",
        :auth       => config.github_api,
        :data       => {"name" => "watson",
                        "color" => "00AEEF" },
        :verbose    => false
      }

      _json, _resp  = Watson::Remote.http_call(opts)

      # [review] - This is pretty messy, maybe clean it up later
      # Check response to validate repo access
      if _resp.code == "404"
        print "\n"
        formatter.print_status "x", RED
        print BOLD + "Unable to access /#{ _owner }/#{ _repo } with given credentials\n" + RESET
        print "      Check that credentials are correct and repository exists under user\n"
        print "      Status: #{ _resp.code } - #{ _resp.message }\n\n"
        return false

      else
        # If it is anything but a 404, I THINK it means we have access...
        # Will assume that until proven otherwise
        print "\n"
        formatter.print_status "o", GREEN
        print BOLD + "Repo successfully accessed\n\n" + RESET
      end

      # Store owner/repo obtained from POST to @config.github_repo
      config.github_repo = "#{ _owner }/#{ _repo }"
      debug_print "Config GitHub API Key updated to: #{ config.github_repo }\n"

      # Inform user of label creation status (created above)
      formatter.print_status "+", GREEN
      print BOLD + "Creating label for watson on GitHub...\n" + RESET
      if _resp.code == "201"
        formatter.print_status "+", GREEN
        print BOLD + "Label successfully created\n" + RESET
      elsif _resp.code == "422" && _json["code"] == "already_exists"
        formatter.print_status "!", YELLOW
        print BOLD + "Label already exists\n" + RESET
      else
        formatter.print_status "x", RED
        print BOLD + "Unable to create label for /#{ _owner }/#{ _repo }\n" + RESET
        print "      Status: #{ _resp.code } - #{ _resp.message }\n"
      end

      # All setup has been completed, need to update RC
      # Call config updater/writer from @config to write config
      debug_print "Updating config with new GitHub info\n"
      config.update_conf("github_api", "github_repo", "github_endpoint")

      # Give user some info
      print "\n"
      formatter.print_status "o", GREEN
      print BOLD + "GitHub successfully setup\n" + RESET
      print "      Issues will now automatically be retrieved from GitHub by default\n"
      print "      Use -u, --update to post issues to GitHub\n"
      print "      See help or README for more details on GitHub/Bitbucket access\n\n"

      return true

    end


    ###########################################################
    # Get all remote GitHub issues and store into Config container class

    def get_issues(config)

      # Identify method entry
      debug_print "#{ self.class } : #{ __method__ }\n"

      # Set up formatter for printing errors
      # config.output_format should be set based on less status by now
      formatter = Printer.new(config).build_formatter

      # Only attempt to get issues if API is specified
      if config.github_api.empty?
        debug_print "No API found, this shouldn't be called...\n"
        return false
      end


      # Get all issues
      # Create options hash to pass to Remote::http_call
      # Issues URL for GitHub + SSL
      opts = {
        :url        => "#{ config.github_endpoint }/repos/#{ config.github_repo }/issues?labels=watson",
        :ssl        => true,
        :method     => "GET",
        :auth       => config.github_api,
        :verbose    => false
      }

      _json, _resp  = Watson::Remote.http_call(opts)


      # Check response to validate repo access
      if _resp.code != "200"
        formatter.print_status "x", RED
        print BOLD + "Unable to access remote #{ config.github_repo }, GitHub API may be invalid\n" + RESET
        print "      Consider running --remote (-r) option to regenerate key\n\n"
        print "      Status: #{ _resp.code } - #{ _resp.message }\n"

        debug_print "GitHub invalid, setting config var\n"
        config.github_valid = false
        return false
      end


      # Create hash entry from each returned issue
      # MD5 of issue serves as hash key
      # Hash value is another hash of info we will use
      _json.each do |issue|

        # Skip this issue if it doesn't have watson md5 tag
        next if (_md5 = issue["body"].match(/__md5__ : (\w+)/)).nil?


        # If it does, use md5 as hash key and populate values with our info
        config.github_issues[_md5[1]] = {
          :title => issue["title"],
          :id    => issue["number"],
          :state => issue["state"]
        }
      end

      config.github_valid = true
    end


    ###########################################################
    # Post given issue to remote GitHub repo
    def post_issue(issue, config)
    # [todo] - Better way to identify/compare remote->local issues than md5
    #        Current md5 based on some things that easily can change, need better ident

      # Identify method entry
      debug_print "#{ self.class } : #{ __method__ }\n"


      # Set up formatter for printing errors
      # config.output_format should be set based on less status by now
      formatter = Printer.new(config).build_formatter


      # Only attempt to get issues if API is specified
      if config.github_api.empty?
        debug_print "No API found, this shouldn't be called...\n"
        return false
      end


      return false if config.github_issues.key?(issue[:md5])
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
      # Issues URL for GitHub + SSL
      opts = {
        :url        => "#{ config.github_endpoint }/repos/#{ config.github_repo }/issues",
        :ssl        => true,
        :method     => "POST",
        :auth       => config.github_api,
        :data       => { "title" => issue[:title] + " [#{ issue[:path] }]",
                         "labels" => [issue[:tag], "watson"],
                         "body" => _body },
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
      config.github_issues[issue[:md5]] = {
        :title => _json["title"],
        :id    => _json["number"],
        :state => _json["state"]
      }
      return true
    end

    private

    def two_factor_authentication(opts, formatter)
      print "\n"
      print "Two Factor Authentication has been enabled for this account.\n"
      print BOLD + "Code: " + RESET
      system "stty -echo"
      _authcode = $stdin.gets.chomp
      system "stty echo"
      print "\n\n"
      if _authcode.empty?
        formatter.print_status "x", RED
        print BOLD + "Input is blank. Please enter your Two Factor Authentication Code!\n\n" + RESET
        return false
      end
      opts[:headers] = [ { :field => "X-GitHub-OTP", :value => _authcode } ]
      _json, _resp  = Remote.http_call(opts)
      if _resp.code == "201"
        formatter.print_status "o", GREEN
        print BOLD + "Obtained OAuth Token\n\n" + RESET
        return [_json, _resp]
      elsif _resp.code == "401"
        formatter.print_status "x", RED
        print BOLD + "Unable to obtain OAuth Token\n" + RESET
        print "      Authentication Code Incorrect!\n\n"
        false
      else
        formatter.print_status "x", RED
        print BOLD + "Unable to obtain OAuth Token\n" + RESET
        print "      Status: #{ _resp.code } - #{ _resp.message }\n\n"
        false
      end
    end
    end
    end
  end
end
