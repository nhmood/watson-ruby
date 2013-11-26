module Watson
  # Dir/File parser class
  # Contains all necessary methods to parse through files and directories
  # for specified tags and generate data structure containing found issues
  class Parser

    # Include for debug_print
    include Watson

    # [review] - Should this require be required higher up or fine here
    # Include for Digest::MD5.hexdigest used in issue creating
    require 'digest'
    require 'pp'

    # Debug printing for this class
    DEBUG = false

    ###########################################################
    # Initialize the parser with the current watson config
    def initialize(config)
      # [review] - Not sure if passing config here is best way to access it

      # Identify method entry
      debug_print "#{ self } : #{ __method__ }\n"

      @config = config
    end


    ###########################################################
    # Begins parsing of files / dirs specified in the initial dir/file lists
    def run

      # Identify method entry
      debug_print "#{ self } : #{ __method__ }\n"

      # Go through all files added from CL (sort them first)
      # If empty, sort and each will do nothing, no errors
      _completed_dirs  = Array.new()
      _completed_files = Array.new()
      if @config.cl_entry_set
        @config.file_list.sort.each do |_file|
          _completed_files.push(parse_file(_file))
        end
      end

      # Then go through all the specified directories
      # Initial parse depth to parse_dir is 0 (unlimited)
      @config.dir_list.sort.each do |_dir|
        _completed_dirs.push(parse_dir(_dir, 0))
      end

      # Create overall hash for parsed files
      _structure           = Hash.new()
      _structure[:files]   = _completed_files
      _structure[:subdirs] = _completed_dirs

      debug_print "_structure dump\n\n"
      debug_print PP.pp(_structure, '')
      debug_print "\n\n"

      _structure
    end


    ###########################################################
    # Parse through specified directory and find all subdirs and files
    def parse_dir(dir, depth)

      # Identify method entry
      debug_print "#{ self } : #{ __method__ }\n"

      # Error check on input
      if Watson::FS.check_dir(dir)
        debug_print "Opened #{ dir } for parsing\n"
      else
        print "Unable to open #{ dir }, exiting\n"
        return false
      end

      debug_print "Parsing through all files/directories in #{ dir }\n"

      # [review] - Shifted away from single Dir.glob loop to separate for dir/file
      # 			 This duplicates code but is much better for readability
      # 			 Not sure which is preferred?


      # Remove leading . or ./
      _glob_dir = dir.gsub(/^\.(\/?)/, '')
      debug_print "_glob_dir: #{_glob_dir}\n"


      # Go through directory to find all files
      # Create new array to hold all parsed files
      _completed_files = Array.new()
      Dir.glob("#{ _glob_dir }{*,.*}").select { |_fn| File.file?(_fn) }.sort.each do |_entry|
        debug_print "Entry: #{_entry} is a file\n"


        # [review] - Warning to user when file is ignored? (outside of debug_print)
        # Check against ignore list, if match, set to "" which will be ignored
        @config.ignore_list.each do |_ignore|
          # [review] - Better "Ruby" way to check for "*"?
          # [review] - Probably cleaner way to perform multiple checks below
          # Look for *.type on list, regex to match entry
          if _ignore[0] == '*'
            _cut = _ignore[1..-1]
            if _entry.match(/#{ _cut }/)
              debug_print "#{ _entry } is on the ignore list, setting to \"\"\n"
              _entry = ''
              break
            end
            # Else check for verbose ignore match
          else
            if  _entry == _ignore || File.absolute_path(_entry) == _ignore
              debug_print "#{ _entry } is on the ignore list, setting to \"\"\n"
              _entry = ''
              break
            end
          end
        end

        # If the resulting entry (after filtering) isn't empty, parse it and push into file array
        unless _entry.empty?
          debug_print "Parsing #{ _entry }\n"
          _completed_files.push(parse_file(_entry))
        end

      end


      # Go through directory to find all subdirs
      # Create new array to hold all parsed subdirs
      _completed_dirs = Array.new()
      Dir.glob("#{ _glob_dir }{*, .*}").select { |_fn| File.directory?(_fn) }.sort.each do |_entry|
        debug_print "Entry: #{ _entry } is a dir\n"

        # Check if entry is in ignore list
        _skip = false
        @config.ignore_list.each do |_ignore|
          if  _entry == _ignore || File.absolute_path(_entry) == _ignore
            debug_print "#{ _entry } is on the ignore list, setting to \"\"\n"
            _skip = true
          end
        end

        # If directory is on the ignore list then skip
        if _skip == true
          _completed_dirs = []
          _completed_files = []
          next
        end

        ## Depth limit logic
        # Current depth is depth of previous parse_dir (passed in as second param) + 1
        _cur_depth = depth + 1
        debug_print "Current Folder depth: #{ _cur_depth }\n"

        # If Config.parse_depth is 0, no limit on subdir parsing
        if @config.parse_depth == 0
          debug_print "No max depth, parsing directory\n"
          _completed_dirs.push(parse_dir("#{ _entry }/", _cur_depth))
        
        # If current depth is less than limit (set in config), parse directory and pass depth
        elsif _cur_depth < @config.parse_depth.to_i + 1
          debug_print "Depth less than max dept (from config), parsing directory\n"
          _completed_dirs.push(parse_dir("#{ _entry }/", _cur_depth))
       
        # Else, depth is greater than limit, ignore the directory
        else
          debug_print "Depth greater than max depth, ignoring\n"
        end

        # Add directory to ignore list so it isn't repeated again accidentally
        @config.ignore_list.push(_entry)
      end


      # [review] - Not sure if Dir.glob requires a explicit directory/file close?

      # Create hash to hold all parsed files and directories
      _structure           = Hash.new()
      _structure[:curdir]  = dir
      _structure[:files]   = _completed_files
      _structure[:subdirs] = _completed_dirs
      _structure
    end


    ###########################################################
    # Parse through individual files looking for issue tags, then generate formatted issue hash
    #noinspection RubyResolve
    def parse_file(filename)
      # [review] - Rename method input param to filename (more verbose?)

      # Identify method entry
      debug_print "#{ self } : #{ __method__ }\n"

      _relative_path = filename
      _absolute_path = File.absolute_path(filename)

      # Error check on input, use input filename to make sure relative path is correct
      if Watson::FS.check_file(_relative_path)
        debug_print "Opened #{ _relative_path } for parsing\n"
        debug_print "Short path: #{ _relative_path }\n"
      else
        print "Unable to open #{ _relative_path }, exiting\n"
        return false
      end


      # Get filetype and set corresponding comment type
      _comment_type = get_comment_type(_relative_path)
      unless _comment_type
        debug_print "Using default (#) comment type\n"
        _comment_type = '#'
      end


      # Open file and read in entire thing into an array
      # Use an array so we can look ahead when creating issues later
      # [review] - Not sure if explicit file close is required here
      # [review] - Better var name than data for read in file?
      _data = Array.new()
      File.open(_absolute_path, 'r').read.each_line do |_line|
        _data.push(_line)
        _line.encode('UTF-8', :invalid => :replace)
      end

      # Initialize issue list hash
      _issue_list = Hash.new()
      _issue_list[:relative_path] = _relative_path
      _issue_list[:absolute_path] = _absolute_path
      _issue_list[:has_issues] = false
      @config.tag_list.each do | _tag |
        debug_print "Creating array named #{ _tag }\n"
        # [review] - Use to_sym to make tag into symbol instead of string?
        _issue_list[_tag] = Array.new
      end

      # Loop through all array elements (lines in file) and look for issues
      _data.each_with_index do |_line, _i|

        # Find any comment line with [tag] - text (any comb of space and # acceptable)
        # Using if match to stay consistent (with config.rb) see there for
        # explanation of why I do this (not a good good one persay...)
        begin
          _mtch = _line.match(/^[#{ _comment_type }+?\s+?]+\[(\w+)\]\s+-\s+(.+)/)
        rescue ArgumentError
          debug_print "Could not encode to UTF-8, non-text\n"
        end

        unless _mtch
          debug_print "No valid tag found in line, skipping\n"
          next
        end

        # Set tag
        _tag = _mtch[1]

        # Make sure that the tag that was found is something we accept
        # If not, skip it but tell user about an unrecognized tag
        unless @config.tag_list.include?(_tag)
          Printer.print_status '!', RED
          print "Unknown tag [#{ _tag }] found, ignoring\n"
          print "      You might want to include it in your RC or with the -t/--tags flag\n"
          next
        end

        # Found a valid match (with recognized tag)
        # Set flag for this issue_list (for file) to indicate that
        _issue_list[:has_issues] = true

        _title = _mtch[2]
        debug_print "Issue found\n"
        debug_print "Tag: #{ _tag }\n"
        debug_print "Issue: #{ _title }\n"

        # Create hash for each issue found
        _issue               = Hash.new
        _issue[:line_number] = _i + 1
        _issue[:title]       = _title

        # Grab context of issue specified by Config param (+1 to include issue itself)
        _context             = _data[_i..(_i + @config.context_depth + 1)]

        # [review] - There has got to be a better way to do this...
        # Go through each line of context and determine indentation
        # Used to preserve indentation in post
        _cut                 = Array.new
        _context.each do |_line_sub|
          _max = 0
          # Until we reach a non indent OR the line is empty, keep slicin'
          until !_line_sub.match(/^( |\t|\n)/) || _line_sub.empty?
            # [fix] - Replace with inplace slice!
            _line_sub = _line_sub.slice(1..-1)
            _max      = _max + 1

            debug_print "New line: #{ _line_sub }\n"
            debug_print "Max indent: #{ _max }\n"
          end

          # Push max indent for current line to the _cut array
          _cut.push(_max)
        end

        # Print old _context
        debug_print "\n\n Old Context \n"
        debug_print PP.pp(_context, '')
        debug_print "\n\n"

        # Trim the context lines to be left aligned but maintain indentation
        # Then add a single \t to the beginning so the Markdown is pretty on GitHub/Bitbucket
        _context.map! { |_line_sub| "\t#{ _line_sub.slice(_cut.min .. -1) }" }

        # Print new _context
        debug_print("\n\n New Context \n")
        debug_print PP.pp(_context, '')
        debug_print("\n\n")

        _issue[:context] = _context

        # These are accessible from _issue_list, but we pass individual issues
        # to the remote poster, so we need this here to reference them for GitHub/Bitbucket
        _issue[:tag]     = _tag
        _issue[:path]    = _relative_path

        # Generate md5 hash for each specific issue (for bookkeeping)
        _issue[:md5]     = ::Digest::MD5.hexdigest("#{ _tag }, #{ _relative_path }, #{ _title }")
        debug_print "#{ _issue }\n"


        # [todo] - Figure out a way to queue up posts so user has a progress bar?
        # That way user can tell that wait is because of http calls not app

        # If GitHub is valid, pass _issue to GitHub poster function
        # [review] - Keep Remote as a static method and pass config every time?
        #			 Or convert to a regular class and make an instance with @config

        if @config.remote_valid
          if @config.github_valid
            debug_print "GitHub is valid, posting issue\n"
            Remote::GitHub.post_issue(_issue, @config)
          else
            debug_print "GitHub invalid, not posting issue\n"
          end


          if @config.bitbucket_valid
            debug_print "Bitbucket is valid, posting issue\n"
            Remote::Bitbucket.post_issue(_issue, @config)
          else
            debug_print "Bitbucket invalid, not posting issue\n"
          end
        end

        # [review] - Use _tag string as symbol reference in hash or keep as string?
        # Look into to_sym to keep format of all _issue params the same
        _issue_list[_tag].push(_issue)

      end

      # [review] - Return of parse_file is different than watson-perl
      # Not sure which makes more sense, ruby version seems simpler
      # perl version might have to stay since hash scoping is weird in perl
      debug_print "\nIssue list: #{ _issue_list }\n"

      _issue_list
    end


    ###########################################################
    # Get comment syntax for given file
    def get_comment_type(filename)

      # Identify method entry
      debug_print "#{ self } : #{ __method__ }\n"

      # Grab the file extension (.something)
      # Check to see whether it is recognized and set comment type
      # If unrecognized, try to grab the next .something extension
      # This is to account for file.cpp.1 or file.cpp.bak, ect

      # [review] - Matz style while loop a la http://stackoverflow.com/a/10713963/1604424
      # Create _mtch var so we can access it outside of the do loop



      _ext = { '.cpp'     => ['//', '/*'],        # C++
               '.cc'      => ['//', '/*'],
               '.hpp'     => ['//', '/*'],
               '.c'       => ['//', '/*'],        # C
               '.h'       => ['//', '/*'],
               '.java'    => ['//', '/*', '/**'], # Java
               '.class'   => ['//', '/*', '/**'],
               '.cs'      => ['//', '/*'],        # C#
               '.js'      => ['//', '/*'],        # JavaScript
               '.php'     => ['//', '/*', '#'],   # PHP
               '.m'       => ['//', '/*'],        # ObjectiveC
               '.mm'      => ['//', '/*'],
               '.go'      => ['//', '/*'],        # Go(lang)
               '.scala'   => ['//', '/*'],        # Scala
               '.erl'     => ['%%', '%'],         # Erlang
               '.hs'      => ['--'],              # Haskell
               '.sh'      => ['#'],               # Bash
               '.rb'      => ['#'],               # Ruby
               '.pl'      => ['#'],               # Perl
               '.pm'      => ['#'],
               '.t'       => ['#'],
               '.py'      => ['#'],               # Python
               '.coffee'  => ['#'],               # CoffeeScript
               '.zsh'     => ['#'],               # Zsh
               '.clj'     => [';;']               # Clojure
             }

      loop do
        _mtch = filename.match(/(\.(\w+))$/)
        debug_print "Extension: #{ _mtch }\n"

        # Break if we don't find a match
        break if _mtch.nil?

        return _ext[_mtch[0]] if _ext.has_key?(_mtch[0])

        # Can't recognize extension, keep looping in case of .bk, .#, ect
        filename = filename.gsub(/(\.(\w+))$/, '')
        debug_print "Didn't recognize, searching #{ filename }\n"

      end

      # We didn't find any matches from the filename, return error (0)
      # Deal with what default to use in calling method
      # [review] - Is Ruby convention to return 1 or 0 (or -1) on failure/error?
      debug_print "Couldn't find any recognized extension type\n"
      false

    end


  end
end
