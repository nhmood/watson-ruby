module Watson

    # Color definitions for pretty printing
    # Defined here because we need Global scope but makes sense to have them
    # in the printer.rb file at least

    BOLD      = "\e[01m"
    UNDERLINE = "\e[4m"
    RESET     = "\e[00m"

    GRAY      = "\e[38;5;0m"
    RED       = "\e[38;5;1m"
    GREEN     = "\e[38;5;2m"
    YELLOW    = "\e[38;5;3m"
    BLUE      = "\e[38;5;4m"
    MAGENTA   = "\e[38;5;5m"
    CYAN      = "\e[38;5;6m"
    WHITE     = "\e[38;5;7m"


  # Printer class that handles all formatting and printing of parsed dir/file structure
  class Printer
    # [review] - Not sure if the way static methods are defined is correct
    #      Ok to have same name as instance methods?
    #      Only difference is where the output gets printed to
    # [review] - No real setup in initialize method, combine it and run method?

    # Include for debug_print (for class methods)
    include Watson

    # Debug printing for this class
    DEBUG = false

    class << self

    # Include for debug_print (for static methods)
    include Watson

    ###########################################################
    # Custom color print for static call (only writes to STDOUT)
    def cprint(msg = '', color = '')
      # Identify method entry
      debug_print "#{ self } : #{ __method__ }\n"

      # This little check will allow us to take a Constant defined color
      # As well as a [0-256] value if specified
      if (color.is_a?(String))
        debug_print "Custom color specified for cprint\n"
        STDOUT.write(color)
      elsif (color.between?(0, 256))
        debug_print "No or Default color specified for cprint\n"
        STDOUT.write("\e[38;5;#{ color }m")
      end

      STDOUT.write(msg)
    end


    ###########################################################
    # Standard header print for static call (uses static cprint)
    def print_header

      # Identify method entry
      debug_print "#{ self } : #{ __method__ }\n"

      # Header
      cprint BOLD + "------------------------------\n" + RESET
      cprint BOLD + "watson" + RESET
      cprint " - " + RESET
      cprint BOLD + YELLOW + "inline issue manager\n" + RESET
      cprint BOLD + "------------------------------\n\n" + RESET

      return true
    end


    ###########################################################
    # Status printer for static call (uses static cprint)
    # Print status block in standard format
    def print_status(msg, color)
      cprint RESET + BOLD
      cprint WHITE + "[ "
      cprint "#{ msg } ", color
      cprint WHITE + "] " + RESET
    end

    end

    ###########################################################
    # Printer initialization method to setup necessary parameters, states, and vars
    def initialize(config)

      # Identify method entry
      debug_print "#{ self } : #{ __method__ }\n"

      @config = config
      return true
    end


    ###########################################################
    # Take parsed structure and print out in specified formatting
    def run(structure)
      # Identify method entry
      debug_print "#{ self } : #{ __method__ }\n"

      formatter = build_formatter
      formatter.run(structure)

      return true
    end

    def build_formatter
      ::Watson::Formatters::DefaultFormatter.new(@config)
    end

  end
end
