require_relative 'watson/command'
require_relative 'watson/config'
require_relative 'watson/fs'
require_relative 'watson/parser'
require_relative 'watson/printer'
require_relative 'watson/formatters'
require_relative 'watson/remote'
require_relative 'watson/github'
require_relative 'watson/bitbucket'
require_relative 'watson/gitlab'
require_relative 'watson/asana'
require_relative 'watson/version'

module Watson
  # [todo] - Replace all regex parentheses() with brackets[] if not matching
  #        Was using () to group things together for syntax instead of []
  #        Replace so we can get cleaner matches and don't need to keep track of matches

  # [todo] - Change debug_print to provide its own \n

  # [todo] - Add ability to pass "IDENTIFY" to debug_print to auto print method entry info

  # [todo] - Make sure all methods have proper return at end

  # [review] - Method input arg always renamed from arg to _arg inside method, change this?
  #        Not sure if I should just make input arg _arg or if explicit _ is useful

  # [todo] - Add option to save output to specified file
  # [todo] - Replace Identify line in each method with method_added call
  #      http://ruby-doc.org/core-2.0.0/Module.html#method-i-method_added


  # Module container for debug mode (which classes to debug print)
  # [review] - This doesn't seem like the right place to put this
  class << self
    attr_accessor :debug_mode
    @@debug_mode = Array.new()
  end


  # [review] - Not sure if module_function is proper way to scope
  # I want to be able to call debug_print without having to use the scope
  # operator (Watson::Printer.debug_print) so it is defined here as a
  # module_function instead of having it in the Printer class
  # Gets included into every class individually
  module_function

  ###########################################################
  # Global debug print that prints based on local file DEBUG flag as well as GLOBAL debug flag
  def debug_print(msg)

    # If nothing set from CLI, debug_mode will be nil
    return if Watson.debug_mode.nil?

    # If empty, just --debug passed, print ALL, else selective print
    _enabled = false
    if !Watson.debug_mode.empty?
      _debug = (self.is_a? Class) ? self.name.downcase : self.class.name.downcase
      Watson.debug_mode.each do |dbg|
        _enabled = true if _debug.include?(dbg)
      end
    else
      _enabled = true
    end

    return if !_enabled
    (msg.is_a? Hash) ? (pp msg) : (print "=> #{msg}")

  end


  ###########################################################
  # Perform system check to see if we are able to use unix less for printing
  def check_less
    # Check if system has less (so we can print out to it to allow scrolling)
    # [todo] - Implement this scrolling thing inside watson with ncurses
    return system("which less > /dev/null 2>&1")
  end

end
