module Watson
  # Command line parser class
  # Controls program flow and parses options given by command line
  class Command

    # Debug printing for this class
    DEBUG = false

    class << self

    # Include for debug_print
    include Watson


    ###########################################################
    # Command line controller
    # Manages program flow from given command line arguments
    def execute(*args)
    # [review] - Should command line args append or overwrite config/RC parameters?
    #        Currently we overwrite, maybe add flag to overwrite or not?

      # Identify method entry
      debug_print "#{ self } : #{ __method__ }\n"

      # List of possible flags, used later in parsing and for user reference
      _flag_list = ["-c", "--context-depth",
                    "-d", "--dirs",
                    "-f", "--files",
                    "-h", "--help",
                    "-i", "--ignore",
                    "-p", "--parse-depth",
                    "-r", "--remote",
                    "-s", "--show",
                    "-t", "--tags",
                    "-u", "--update",
                    "-v", "--version"
                   ]


      # If we get the version or help flag, ignore all other flags
      # Just display these and exit
      # Using .index instead of .include? to stay consistent with other checks
      return help         if args.index('-h') != nil  || args.index('--help')    != nil
      return version      if args.index('-v') != nil  || args.index('--version') != nil



      # If not one of the above then we are performing actual watson stuff
      # Create all the necessary watson components so we can perform
      # all actions associated with command line args


      # Only create Config, don't call run method
      # Populate Config parameters from CL THEN call run to fill in gaps from RC
      # Saves some messy checking and sorting/organizing of parameters
      @config   = Watson::Config.new
      @parser   = Watson::Parser.new(@config)
      @printer  = Watson::Printer.new(@config)

      # Capture Ctrl+C interrupt for clean exit
      # [review] - Not sure this is the correct place to put the Ctrl+C capture
      trap("INT") do
        File.delete(@config.tmp_file) if File.exists?(@config.tmp_file)
        exit 2
      end

      # Parse command line options
      # Begin by slicing off until we reach a valid flag

      # Always look at first array element in case and then slice off what we need
      # Accept parameters to be added / overwritten if called twice
      # Slice out from argument until next argument

      # Clean up argument list by removing elements until the first valid flag
      until _flag_list.include?(args[0]) || args.length == 0
        # [review] - Make this non-debug print to user?
        debug_print "Unrecognized flag #{ args[0] }\n"
        args.slice!(0)
      end

      # Parse command line options
      # Grab flag (should be first arg) then slice off args until next flag
      # Repeat until all args have been dealt with

      until args.length == 0
        # Set flag for calling function later
        _flag = args.slice!(0)

        debug_print "Current Flag: #{ _flag }\n"

        # Go through args until we find the next valid flag or all args are parsed
        _i = 0
        until _flag_list.include?(args[_i]) ||  _i > (args.length - 1)
          debug_print "Arg: #{ args[_i] }\n"
          _i = _i + 1
        end

        # Slice off the args for the flag (inclusive) using index from above
        # [review] - This is a bit messy (to slice by _i - 1) when we have control
        # over the _i index above but I don't want to
        # think about the logic right now so look at later
        _flag_args = args.slice!(0..(_i-1))

        case _flag
        when "-c", "--context-depth"
          debug_print "Found -c/--context-depth argument\n"
          set_context(_flag_args)

        when "-d", "--dirs"
          debug_print "Found -d/--dirs argument\n"
          set_dirs(_flag_args)

        when "-f", "--files"
          debug_print "Found -f/--files argument\n"
          set_files(_flag_args)

        when "-i", "--ignore"
          debug_print "Found -i/--ignore argument\n"
          set_ignores(_flag_args)

        when "-p", "--parse-depth"
          debug_print "Found -r/--parse-depth argument\n"
          set_parse_depth(_flag_args)

        when "-r", "--remote"
          debug_print "Found -r/--remote argument\n"
          # Run config to populate all the fields and such
          # [review] - Not a fan of running these here but want to avoid getting all issues when running remote (which @config.run does)
          @config.check_conf
          @config.read_conf
          setup_remote(_flag_args)

          # If setting up remote, exit afterwards
          exit true

        when "-s", "--show"
          debug_print "Found -s/--show argument\n"
          set_show_type(_flag_args)

        when "-t", "--tags"
          debug_print "Found -t/--tags argument\n"
          set_tags(_flag_args)

        when "-u", "--update"
          debug_print "Found -u/--update argument\n"
          @config.remote_valid =  true


        else
          print "Unknown argument #{ _flag }\n"
        end
      end

      debug_print "Args length 0, running watson...\n"
      @config.run
      structure = @parser.run
      @printer.run(structure)
    end


    ###########################################################
    # Print help for watson
    def help
      # [todo] - Add bold and colored printing

      # Identify method entry
      debug_print "#{ self } : #{ __method__ }\n"

      puts <<-HELP.gsub(/^ {,6}/, '')
      #{BOLD}Usage: watson [OPTION]...
      Running watson with no arguments will parse with settings in RC file
      If no RC file exists, default RC file will be created

         -c, --context-depth   number of lines of context to provide with posted issue
         -d, --dirs            list of directories to search in
         -f, --files           list of files to search in
         -h, --help            print help
         -i, --ignore          list of files, directories, or types to ignore
         -p, --parse-depth     depth to recursively parse directories
         -r, --remote          list / create tokens for Bitbucket/GitHub
         -t, --tags            list of tags to search for
         -u, --update          update remote repos with current issues
         -v, --version      print watson version and info

      Any number of files, tags, dirs, and ignores can be listed after flag
      Ignored files should be space separated
      To use *.filetype identifier, encapsulate in \"\" to avoid shell substitutions

      Report bugs to: watson\@goosecode.com
      watson home page: <http://goosecode.com/projects/watson>
      [goosecode] labs | 2012-2013#{RESET}
      HELP

      return true
    end


    ###########################################################
    # Print version information about watson
    def version
      # Identify method entry
      debug_print "#{ self } : #{ __method__ }\n"

      puts <<-VERSION.gsub(/^ {,6}/, '')
      watson v#{::Watson::VERSION}
      Copyright (c) 2012-2013 goosecode labs
      Licensed under MIT, see LICENSE for details

      Written by nhmood, see <http://goosecode.com/projects/watson>
      VERSION

      return true
    end


    ###########################################################
    # set_context
    # Set context_depth parameter in config
    def set_context(args)

      # Identify method entry
      debug_print "#{ self } : #{ __method__ }\n"

      # Need at least one dir in args
      if args.length <= 0
        # [review] - Make this a non-debug print to user?
        debug_print "No args passed, exiting\n"
        return false
      end


      # For context_depth we do NOT append to RC, ALWAYS overwrite
      # For each argument passed, make sure valid, then set @config.parse_depth
      args.each do | _context_depth |
        if _context_depth.match(/^(\d+)/)
          debug_print "Setting #{ _context_depth } to config context_depth\n"
          @config.context_depth = _context_depth.to_i
        else
          debug_print "#{ _context_depth } invalid depth, ignoring\n"
        end
      end

      # Doesn't make much sense to set context_depth for each individual post
      # When you use this command line arg, it writes the config parameter
      @config.update_conf("context_depth")

      debug_print "Updated context_depth: #{ @config.context_depth }\n"
      return true
    end


    ###########################################################
    # set_dirs
    # Set directories to be parsed by watson
    def set_dirs(args)

      # Identify method entry
      debug_print "#{ self } : #{ __method__ }\n"

      # Need at least one dir in args
      if args.length <= 0
        # [review] - Make this a non-debug print to user?
        debug_print "No args passed, exiting\n"
        return false
      end

      # Set config flag for CL entryset  in config
      @config.cl_entry_set = true
      debug_print "Updated cl_entry_set flag: #{ @config.cl_entry_set }\n"

      # [review] - Should we clean the dir before adding here?
      # For each argument passed, make sure valid, then add to @config.dir_list
      args.each do | _dir |
        # Error check on input
        if !Watson::FS.check_dir(_dir)
          print "Unable to open #{ _dir }\n"
        else
          # Clean up directory path
          _dir = _dir.match(/^((\w+)?\.?\/?)+/)[0].gsub(/(\/)+$/, "")
          if !_dir.empty?
            debug_print "Adding #{ _dir } to config dir_list\n"
            @config.dir_list.push(_dir)
          end
        end
      end

      debug_print "Updated dirs: #{ @config.dir_list }\n"
      return true
    end


    ###########################################################
    # set_files
    # Set files to be parsed by watson
    def set_files(args)

      # Identify method entry
      debug_print "#{ self } : #{ __method__ }\n"

      # Need at least one file in args
      if args.length <= 0
        debug_print "No args passed, exiting\n"
        return false
      end

      # Set config flag for CL entryset  in config
      @config.cl_entry_set = true
      debug_print "Updated cl_entry_set flag: #{ @config.cl_entry_set }\n"

      # For each argument passed, make sure valid, then add to @config.file_list
      args.each do | _file |
        # Error check on input
        if !Watson::FS.check_file(_file)
          print "Unable to open #{ _file }\n"
        else
          debug_print "Adding #{ _file } to config file_list\n"
          @config.file_list.push(_file)
        end
      end

      debug_print "Updated files: #{ @config.file_list }\n"
      return true
    end


    ###########################################################
    # set_ignores
    # Set files and dirs to be ignored when parsing by watson
    def set_ignores(args)

      # Identify method entry
      debug_print "#{ self } : #{ __method__ }\n"

      # Need at least one ignore in args
      if args.length <= 0
        debug_print "No args passed, exiting\n"
        return false
      end

      # Set config flag for CL ignore set in config
      @config.cl_ignore_set = true
      debug_print "Updated cl_ignore_set flag: #{ @config.cl_ignore_set }\n"


      # For ignores we do NOT overwrite RC, just append
      # For each argument passed, add to @config.ignore_list
      args.each do | _ignore |
        debug_print "Adding #{ _ignore } to config ignore_list\n"
        @config.ignore_list.push(_ignore)
      end

      debug_print "Updated ignores: #{ @config.ignore_list }\n"
      return true
    end


    ###########################################################
    # set_parse_depth
    # Set how deep to recursively parse directories
    def set_parse_depth(args)

      # Identify method entry
      debug_print "#{ self } : #{ __method__ }\n"

      # This should be a single, numeric, value
      # If they pass more, just take the last valid value
      if args.length <= 0
        debug_print "No args passed, exiting\n"
        return false
      end

      # For max_dpeth we do NOT append to RC, ALWAYS overwrite
      # For each argument passed, make sure valid, then set @config.parse_depth
      args.each do | _parse_depth |
        if _parse_depth.match(/^(\d+)/)
          debug_print "Setting #{ _parse_depth } to config parse_depth\n"
          @config.parse_depth = _parse_depth
        else
          debug_print "#{ _parse_depth } invalid depth, ignoring\n"
        end
      end

      debug_print "Updated parse_depth: #{ @config.parse_depth }\n"
      return true
    end


    ###########################################################
    # set_tags
    # Set tags to look for when parsing files and folders
    def set_tags(args)

      # Identify method entry
      debug_print "#{ self } : #{ __method__ }\n"

      # Need at least one tag in args
      if args.length <= 0
        debug_print "No args passed, exiting\n"
        return false
      end

      # Set config flag for CL tag set in config
      @config.cl_tag_set = true
      debug_print "Updated cl_tag_set flag: #{ @config.cl_tag_set }\n"

      # If set from CL, we overwrite the RC parameters
      # For each argument passed, add to @config.tag_list
      args.each do | _tag |
        debug_print "Adding #{ _tag } to config tag_list\n"
        @config.tag_list.push(_tag)
      end

      debug_print "Updated tags: #{ @config.tag_list }\n"
      return true
    end


    ###########################################################
    # setup_remote
    # Handle setup of remote issue posting for GitHub and Bitbucket
    def setup_remote(args)

      # Identify method entry
      debug_print "#{ self } : #{ __method__ }\n"

      Printer.print_header

      print BOLD + "Existing Remotes:\n" + RESET

      # Check the config for any remote entries (GitHub or Bitbucket) and print
      # We *should* always have a repo + API together, but API should be enough
      if @config.github_api.empty? && @config.bitbucket_api.empty?
        Printer.print_status "!", YELLOW
        print BOLD + "No remotes currently exist\n\n" + RESET
      end

      if !@config.github_api.empty?
        print BOLD + "GitHub User : " + RESET + "#{ @config.github_api }\n"
        print BOLD + "GitHub Repo : " + RESET + "#{ @config.github_repo }\n\n"
      end

      if !@config.bitbucket_api.empty?
        print BOLD + "Bitbucket User : " + RESET + "#{ @config.bitbucket_api }\n" + RESET
        print BOLD + "Bitbucket Repo : " + RESET + "#{ @config.bitbucket_repo }\n\n" + RESET
      end

      # If github or bitbucket passed, setup
      # If just -r (0 args) do nothing and only have above printed
      # If more than 1 arg is passed, unrecognized, warn user
      if args.length == 1
        case args[0].downcase
        when "github"
          debug_print "GitHub setup called from CL\n"
          Watson::Remote::GitHub.setup(@config)

        when "bitbucket"
          debug_print "Bitbucket setup called from CL\n"
          Watson::Remote::Bitbucket.setup(@config)
        end
      elsif args.length > 1
        Printer.print_status "x", RED
        puts <<-SUMMERY.gsub(/^ {,8}/, '')
        #{BOLD}Incorrect arguments passed#{RESET}
        Please specify either Github or Bitbucket to setup remote
        Or pass without argument to see current remotes
        See help (-h/--help) for more details
        SUMMERY

        return false
      end
    end


    ###########################################################
    # set_show
    # Set what files watson should show
    def set_show_type(args)

      # Identify method entry
      debug_print "#{ self } : #{ __method__ }\n"

      # This should be a single value, either all, clean, or dirty
      # If they pass more, just take the last valid value
      if args.length <= 0
        debug_print "No args passed, exiting\n"
        return false
      end

      args.each do | _show |
        case _show.downcase
        when 'clean'
          debug_print "Setting config show to #{ _show }\n"
          @config.show_type = 'clean'

        when 'dirty'
          debug_print "Setting config show to #{ _show }\n"
          @config.show_type = 'dirty'

        else
          debug_print "Setting config show to #{ _show }\n"
          @config.show_type = 'all'
        end

      end

      debug_print "Updated show to: #{ @config.show_type }\n"
      return true
    end
    end
  end
end
