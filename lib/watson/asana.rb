module Watson

  class Remote

    class Asana

      @end_point = "https://app.asana.com/api/1.0"
      @formatter = nil

      # Debug printing for this class
      DEBUG = true

      class << self

        # [todo] - post issue to diff. project in same workspace depending on config?

        # Include for debug_print
        include Watson

        #############################################################################
        # Setup remote access to Asana
        # Get API Key, Workspace, Project
        def setup(config)

          @formatter = Printer.new(config).build_formatter

          # Identify method entry
          debug_print "#{ self.class } : #{ __method__ }\n"

          @formatter.print_status "+", GREEN
          print BOLD + "Setting up Asana...\n" + RESET

          config_exists = config.asana_api.empty? && config.asana_workspace.empty? && config.asana_project.empty?
          unless config_exists
            @formatter.print_status "!", RED
            print BOLD + "Previous Asana API is in RC, are you sure you want to overwrite?\n" + RESET
            print "      (Y)es/(N)o: "

            # Get user input
            _overwrite = $stdin.gets.chomp
            if ["no", "n"].include?(_overwrite.downcase)
              print "\n\n"
              @formatter.print_status "x", RED
              print BOLD + "Not overwriting current Asana config\n" + RESET
              return false
            end
          end

          @formatter.print_status "!", YELLOW
          print BOLD + "Asana API key required to make/update issues\n" + RESET
          print "      See help or README for more details on Asana access\n\n"

          print "\n"

          print BOLD + "API Key: " + RESET
          _api_key = $stdin.gets.chomp
          if _api_key.empty?
            @formatter.print_status "x", RED
            print BOLD + "Input blank. Please enter your api key!\n\n" + RESET
            return false
          end

          print BOLD + "Workspace: " + RESET
          _workspace = $stdin.gets.chomp
          if _workspace.empty?
            @formatter.print_status "x", RED
            print BOLD + "Input blank. Please enter your workspace!\n\n" + RESET
            return false
          end

          print BOLD + "Project: " + RESET
          _project = $stdin.gets.chomp
          if _project.empty?
            @formatter.print_status "x", RED
            print BOLD + "Input blank. Please enter your project!\n\n" + RESET
            return false
          end

          workspace_dict = get_workspaces(_api_key)

          unless workspace_dict
            @formatter.print_status "x", RED
            print BOLD + "Asana setup failed\n" + RESET
            return false
          end

          unless workspace_dict.include?(_workspace)
            print "\n"
            @formatter.print_status "x", RED
            print BOLD + "Workspace doesn't exist\n" + RESET
            print "      Check that the workspace name is correct\n"
            print "      Possible workspaces: '#{ workspace_dict.keys.join('\', \'') }'\n\n"
            return false
          end

          workspace_id = workspace_dict[_workspace]
          project_dict = get_projects(_api_key, workspace_id)

          unless project_dict
            @formatter.print_status "x", RED
            print BOLD + "Asana API Request failed\n" + RESET
            return false
          end

          unless project_dict.include?(_project)
            print "\n"
            @formatter.print_status "x", RED
            print BOLD + "Project doesn't exist within workspace '#{ _workspace }'\n" + RESET
            print "      Check that the project name is correct\n"
            print "      Possible projects: '#{ project_dict.keys.join('\', \'') }'\n\n"
            return false
          end

          config.asana_api = _api_key
          debug_print "Asana API Key updated to: #{ config.asana_api }\n"
          config.asana_workspace = _workspace
          debug_print "Asana Workspace updated to: #{ config.asana_workspace }\n"
          config.asana_project = _project
          debug_print "Asana Project updated to: #{ config.asana_project }\n"

          # All setup has been completed, need to update RC
          # Call config updater/writer from @config to write config
          debug_print "Updating config with new Asana info\n"
          config.update_conf("asana_api", "asana_workspace", "asana_project")

          # Give user some info
          print "\n"
          @formatter.print_status "o", GREEN
          print BOLD + "Asana successfully setup\n" + RESET
          print "      Issues will now automatically be retrieved from Asana by default\n"
          print "      Use -u, --update to post issues to Asana\n"
          print "      See help or README for more details on GitHub/Bitbucket/Asana access\n\n"

          true

        end

        ###########################################################
        # Post given issue to Asana project
        def post_issue(issue, config)

          # Identify method entry
          debug_print "#{ self.class } : #{ __method__ }\n"

          # Set up formatter for printing errors
          # config.output_format should be set based on less status by now
          @formatter = Printer.new(config).build_formatter

          # Only attempt to get issues if API is specified
          if config.asana_api.empty?
            debug_print "No asana API found, this shouldn't be called...\n"
            return false
          end

          return false if config.asana_issues.key?(issue[:md5])
          debug_print "#{issue[:md5]} not found in remote issues, posting\n"

          _api_key = config.asana_api
          _workspace = config.asana_workspace
          _project = config.asana_project

          workspace_id = get_workspace_id(_api_key, _workspace)

          unless workspace_id
            @formatter.print_status "x", RED
            print BOLD + "Unable to get workspace info from Asana API\n" + RESET
            return false
          end

          tags = init_tags(config, _api_key, workspace_id)

          unless tags
            @formatter.print_status "x", RED
            print BOLD + "Unable to initialise tags\n" + RESET
            return false
          end

          project_id = get_project_identifier(_api_key, _project, workspace_id)

          unless project_id
            @formatter.print_status "x", RED
            print BOLD + "Unable to get project info from Asana API\n" + RESET
            return false
          end

          tasks_url = "#{ @end_point }/workspaces/#{ workspace_id }/tasks"

          # Create the body text for the issue here, too long to fit nicely into opts hash
          _body =
              "__filename__ : #{ issue[:path] }\n" +
                  "__line #__ : #{ issue[:line_number] }\n" +
                  "__tag__ : #{ issue[:tag] }\n" +
                  "__md5__ : #{ issue[:md5] }\n\n" +
                  "#{ issue[:context].join }\n"

          opts = {
              :url => tasks_url,
              :ssl => true,
              :method => "POST",
              :basic_auth => [_api_key, ""],
              :data => [{"name" => issue[:title],
                         "notes" => _body,
                         "projects" => project_id}],
              :verbose => false
          }

          _json, _resp = Watson::Remote.http_call(opts)

          unless _resp.code == "201"
            @formatter.print_status "x", RED
            print BOLD + "Unable to access Asana API, key may be invalid\n" + RESET
            print "      Consider running --remote (-r) option to regenerate key\n\n"
            print "      Status: #{ _resp.code } - #{ _resp.message }\n"
            return false
          end

          _data = _json["data"]
          new_task_id = _data["id"]

          debug_print "creating file tag"
          file_tag = create_or_get_tag(_api_key,workspace_id,issue[:path])
          debug_print "tagging with file tag <#{ file_tag }>"

          if file_tag
            file_tag_id = file_tag['id']
            unless tag_task(_api_key, new_task_id, file_tag_id)
              @formatter.print_status "!", RED
              print BOLD + "Unable to tag with '#{ issue[:path] }'\n" + RESET
            end
          else
            @formatter.print_status "!", RED
            print BOLD + "Unable create tag '#{ issue[:path] }'\n" + RESET
          end

          debug_print "tagging with issue tag <#{ issue[:tag] }>"
          issue_tag_id = tags[issue[:tag]]['id']
          unless tag_task(_api_key, new_task_id, issue_tag_id)
            @formatter.print_status "!", RED
            print BOLD + "Unable to tag with '#{ issue[:tag] }'\n" + RESET
          end

          debug_print "tagging with watson tag"
          watson_tag_id = tags['watson']['id']
          unless tag_task(_api_key, new_task_id, watson_tag_id)
            @formatter.print_status "!", RED
            print BOLD + "Unable to tag with 'watson'\n" + RESET
          end

          # Parse response and append issue hash so we are up to date
          config.asana_issues[issue[:md5]] = {
              :title => _data["name"],
              :id    => _data["id"],
              :state => _data["completed"]
          }

          true

        end

        ###########################################################
        # Get all remote Asana issues and store into Config container class
        def get_issues(config)

          # Identify method entry
          debug_print "#{ self.class } : #{ __method__ }\n"

          # Set up formatter for printing errors
          # config.output_format should be set based on less status by now
          @formatter = Printer.new(config).build_formatter

          # Only attempt to get issues if API is specified
          if config.asana_api.empty?
            debug_print "No asana API found, this shouldn't be called...\n"
            return false
          end

          _api_key = config.asana_api
          _workspace = config.asana_workspace
          _project = config.asana_project

          task_records = get_tasks(_api_key, _project, _workspace)

          unless task_records
            config.asana_valid = false
            return false
          end

          task_records.each do |issue|
            # Skip this issue if it doesn't have watson md5 tag
            _md5 = issue["notes"].match(/.*__md5__ : (\w+)\s.*/)
            next if (_md5).nil?

            # If it does, use md5 as hash key and populate values with our info
            config.asana_issues[_md5[1]] = {
                :title => issue["name"],
                :id    => issue["id"],
                :state => issue["completed"] # TODO: How to check status?
            }
          end

          config.asana_valid = true

        end

        private

          ###########################################################
          # Return all projects under the given api_key/workspace
          def get_projects(_api_key, workspace_id)

            debug_print "#{ self.class } : #{ __method__ }\n"

            projects_url = "#{ @end_point }/workspaces/#{ workspace_id}/projects"

            opts = {
                :url => projects_url,
                :ssl => true,
                :method => "GET",
                :basic_auth => [_api_key, ""],
                :verbose => false
            }

            _json, _resp = Watson::Remote.http_call(opts)

            if _resp.code != "200"
              print "\n"
              @formatter.print_status "x", RED
              print BOLD + "Unable to access project list\n" + RESET
              print "       Status: #{ _resp.code } - #{ _resp.message }\n\n"
              return false
            end

            project_list = _json["data"]
            project_dict = {}
            project_list.each { |x| project_dict[x["name"]] = x["id"] }
            project_dict
          end

          ###########################################################
          # Return all workspaces under the given API key
          def get_workspaces(_api_key)

            debug_print "#{ self.class } : #{ __method__ }\n"

            workspaces_url = "#{ @end_point }/workspaces"

            opts = {
                :url => workspaces_url,
                :ssl => true,
                :method => "GET",
                :basic_auth => [_api_key, ""],
                :verbose => false
            }

            _json, _resp = Watson::Remote.http_call(opts)

            if _resp.code != "200"
              print "\n"
              @formatter.print_status "x", RED
              print BOLD + "Unable to access workspace list with given credentials\n" + RESET
              print "       Check that API key is correct\n"
              print "       Status: #{ _resp.code } - #{ _resp.message }\n\n"
              return false
            end

            workspace_list = _json["data"]
            workspace_dict = {}
            workspace_list.each { |x| workspace_dict[x["name"]] = x["id"] }
            workspace_dict
          end

          ###########################################################
          # Return all tasks in given project/workspace
          def get_tasks(_api_key, _project, _workspace)

            debug_print "#{ self.class } : #{ __method__ }\n"

            workspace_id = get_workspace_id(_api_key, _workspace)

            unless workspace_id
              @formatter.print_status "x", RED
              print BOLD + "Unable to get workspace info from Asana API\n" + RESET
              return false          end

            project_id = get_project_identifier(_api_key, _project, workspace_id)

            unless project_id
              @formatter.print_status "x", RED
              print BOLD + "Unable to get project info from Asana API\n" + RESET
              return false
            end

            tasks_url = "#{ @end_point }/projects/#{ project_id }/tasks?opt_fields=name,notes,completed&include_archived=true"

            opts = {
                :url => tasks_url,
                :ssl => true,
                :method => "GET",
                :basic_auth => [_api_key, ""],
                :verbose => false
            }

            _json, _resp = Watson::Remote.http_call(opts)

            # Check response to validate repo access
            if _resp.code != "200"
              @formatter.print_status "x", RED
              print BOLD + "Unable to access Asana API, key may be invalid\n" + RESET
              print "      Consider running --remote (-r) option to regenerate key\n\n"
              print "      Status: #{ _resp.code } - #{ _resp.message }\n"

              debug_print "Asana invalid, setting config var\n"
              #return false
            end

            _json["data"]

          end

          ###########################################################
          # Return full record for a particular task
          def get_task_record(_api_key, task_id)

            debug_print "#{ self.class } : #{ __method__ }\n"

            task_url = "#{ @end_point }/tasks/#{ task_id }"

            opts = {
                :url => task_url,
                :ssl => true,
                :method => "GET",
                :basic_auth => [_api_key, ""],
                :verbose => false
            }

            _json, _resp = Watson::Remote.http_call(opts)

            if _resp.code != "200"
              @formatter.print_status "x", RED
              print BOLD + "Unable to get task, API key may be invalid\n" + RESET
              print "      Consider running --remote (-r) option to regenerate key\n\n"
              print "      Status: #{ _resp.code } - #{ _resp.message }\n"
              return false
            end

            _json["data"]
          end

          ###########################################################
          # Get project id given project and work space name
          def get_project_identifier(_api_key, _project, workspace_id)
            debug_print "#{ self.class } : #{ __method__ }\n"
            projects_dict = get_projects(_api_key, workspace_id)
            unless projects_dict
              return false
            end
            projects_dict[_project]
          end

          ###########################################################
          # Get workspace id given workspace name
          def get_workspace_id(_api_key, _workspace)
            debug_print "#{ self.class } : #{ __method__ }\n"
            workspace_dict = get_workspaces(_api_key)
            unless workspace_dict
              return false
            end
            workspace_dict[_workspace]
          end

          ###########################################################
          # Tags task with task_id with the tag specified by tag_id
          def tag_task(_api_key, task_id, tag_id)
            debug_print "#{ self.class } : #{ __method__ }\n"

            tags_url = "#{ @end_point }/tasks/#{ task_id }/addTag"

            opts = {
                :url => tags_url,
                :ssl => true,
                :method => "POST",
                :basic_auth => [_api_key, ""],
                :data => [{"tag" => tag_id}],
                :verbose => false
            }

            _json, _resp = Watson::Remote.http_call(opts)

            unless _resp.code == "200"
              @formatter.print_status "x", RED
              print BOLD + "Unable to access Asana API, key may be invalid\n" + RESET
              print "      Consider running --remote (-r) option to regenerate key\n\n"
              print "      Status: #{ _resp.code } - #{ _resp.message }\n"
              return false
            end

            _json['data']

          end

          ###########################################################
          # Returns hash, tag name => tag
          def get_tags(_api_key, _workspace_id)
            debug_print "#{ self.class } : #{ __method__ }\n"

            tags_url = "#{ @end_point }/workspaces/#{ _workspace_id }/tags"

            opts = {
                :url => tags_url,
                :ssl => true,
                :method => "GET",
                :basic_auth => [_api_key, ""],
                :verbose => false
            }

            _json, _resp = Watson::Remote.http_call(opts)

            unless _resp.code == "200"
              @formatter.print_status "x", RED
              print BOLD + "Unable to access Asana API, key may be invalid\n" + RESET
              print "      Consider running --remote (-r) option to regenerate key\n\n"
              print "      Status: #{ _resp.code } - #{ _resp.message }\n"
              return false
            end

            # [review] - fancy ruby way of generating this hash?

            _tags_dict = {}
            _json['data'].each { |x| _tags_dict[x['name']] = x }
            _tags_dict

          end

          ###########################################################
          # Make sure base tags exist (tag_list + the watson tag), add them if not
          def init_tags(config, _api_key, _workspace_id)
            debug_print "#{ self.class } : #{ __method__ }\n"
            tags_to_check = config.tag_list.dup << 'watson'
            create_and_get_tags(_api_key, _workspace_id, tags_to_check)
          end

          ###########################################################
          # Adds 'tags_to_add' and returns full list of tags.
          # The reason that this is combined into one method is that
          # Asana do not actually 'create' the tag properly until
          # it has been used to tag a task
          def create_and_get_tags(_api_key, _workspace_id, tags_to_add)
            debug_print "#{ self.class } : #{ __method__ }\n"

            _tags = get_tags(_api_key, _workspace_id)

            unless _tags
              return false
            end

            debug_print "Checking that tags #{ tags_to_add } exist\n"
            tags_to_create = tags_to_add - _tags.keys
            if tags_to_create
              debug_print "Need to create tags #{ tags_to_create }\n"
            end
            tags_to_create.each do |tag_name|
              _tag = create_tag(_api_key, _workspace_id, tag_name)
              unless _tag
                return false
              end
              _tags[_tag['name']] = _tag
            end

            _tags
          end

          ###########################################################
          # Creates a tag in the given workspace
          def create_tag(_api_key, _workspace_id, tag)
            debug_print "#{ self.class } : #{ __method__ }\n"

            opts = {
                :url => "#{ @end_point }/workspaces/#{ _workspace_id }/tags",
                :ssl => true,
                :method => "POST",
                :basic_auth => [_api_key, ""],
                :data => [{'name'=>tag}],
                :verbose => false
            }

            _json, _resp = Watson::Remote.http_call(opts)

            unless _resp.code == "201"
              @formatter.print_status "x", RED
              print BOLD + "Unable to access Asana API, key may be invalid\n" + RESET
              print "      Consider running --remote (-r) option to regenerate key\n\n"
              print "      Status: #{ _resp.code } - #{ _resp.message }\n"
              return false
            end

            _data = _json['data']

            debug_print "Created tag '#{ tag }' with id #{ _data['id'] } \n"

            _data

          end

          ###########################################################
          # Creates a tag in the given workspace or else if already
          # exists, returns that tag
          def create_or_get_tag(_api_key, _workspace_id, tag_name)
            debug_print "#{ self.class } : #{ __method__ }\n"
            _tags = create_and_get_tags(_api_key, _workspace_id, [tag_name])
            _tags ? _tags[tag_name] : false
          end

      end

      end

  end

end