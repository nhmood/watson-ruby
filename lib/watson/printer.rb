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

    ###########################################################
    # Printer initialization method to setup necessary parameters, states, and vars
    def initialize(config)
      # Identify method entry
      debug_print "#{self} : #{__method__}\n"
      @config = config
    end

    ###########################################################
    # Take parsed structure and print out in specified formatting
    def run(structure)
      # Identify method entry
      debug_print "#{self} : #{__method__}\n"

      build_formatter.run(structure)
    end

    private

    def build_formatter
      @formatter ||= @config.output_format.new(@config)
    end
  end
end
