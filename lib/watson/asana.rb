module Watson

  class Remote

    class Asana

      # Debug printing for this class
      DEBUG = false

      class << self

        # [todo] - post issue to diff. project in same workspace depending on config?

        # Include for debug_print
        include Watson

        #############################################################################
        # Setup remote access to Asana
        # Get Username, Workspace, Project, Password
        def setup(config)

          print_debug
          print_access_attempt
          if accepts_config_overwrite(config)
            print_access_required
            username = get_username_from_stdin
            if username
              token = get_oauth_token_from_asana(username)
              if token

              end
            end
          end

        end

        def print_access_required
          Printer.print_status "!", YELLOW
          print BOLD + "Access to your Asana account required to make/update issues\n" + RESET
          print "      See help or README for more details on Asana access\n\n"
        end

        def get_oauth_token_from_asana(username)
          # [todo] get oauth token from asana

        end

        def get_username_from_stdin
          # [todo] - Don't just check for blank password but invalid as well
          # Poor mans username/password grabbing
          print BOLD + "Username: " + RESET
          _username = $stdin.gets.chomp
          if _username.empty?
            Printer.print_status "x", RED
            print BOLD + "Input blank. Please enter your username!\n\n" + RESET
          end
          _username
        end

        def accepts_config_overwrite(config)
          api_config = config.asana_api
          workspace_config = config.asana_workspace
          project_config = config.asana_project

          unless api_config.empty? && workspace_config.empty? && project_config.empty?
            Printer.print_status "!", RED
            print BOLD + "Previous Asana Configuration is in RC, are you sure you want to overwrite?\n" + RESET
            print "      (Y)es/(N)o: "

            # Get user input
            _overwrite = $stdin.gets.chomp
            if ["no", "n"].include?(_overwrite.downcase)
              print "\n"
              Printer.print_status "x", RED
              print BOLD + "Not overwriting current Asana configuration\n" + RESET
              return false
            end
          end

          return true
        end

        ###########################################################
        # Get all remote Asana issues and store into Config container class
        def get_issues(config)

        end

        ###########################################################
        # Post given issue to Asana workspace/project
        def post_issue(issue, config)

        end

    private :cancel_due_to_existing_config





      end

        def print_access_attempt
          Printer.print_status "+", GREEN
          print BOLD + "Attempting to access Asana...\n" + RESET
        end

        def print_debug
          debug_print "#{ self.class } : #{ __method__ }\n"
        end

      end

  end

end