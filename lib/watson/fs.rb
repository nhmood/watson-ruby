module Watson
  # File system utility function class 
  # Contains all methods for file access in watson 
  class FS 
    
    # Debug printing for this class
    DEBUG = false
  
    class << self
    # [todo] - Not sure whether to make check* methods return FP
    #      Makes it nice to get it returned and use it but
    #      not sure how to deal with closing the FP after
    #      Currently just close inside

    # Include for debug_print
    include Watson
    
    ###########################################################
    # Check if file exists and can be opened
    def check_file(file)
      
      # Identify method entry
      debug_print "#{ self } : #{ __method__ }\n"
    
      # Error check for input
      if file.length == 0
        debug_print "No file specified\n" 
        return false
      end

      # Check if file can be opened
      if File.readable?(file)
        debug_print "#{ file } exists and opened successfully\n"
        return true
      else
        debug_print "Could not open #{ file }, skipping\n"
        return false
      end         
    end


    ###########################################################
    # Check if directory exists and can be opened 
    def check_dir(dir)
      
      # Identify method entry
      debug_print "#{ self } : #{ __method__ }\n"
  
      # Error check for input
      if dir.length == 0
        debug_print "No directory specified\n"
        return false
      end

      # Check if directory exists 
      if Dir.exists?(dir)
        debug_print "#{ dir } exists and opened succesfully\n"
        return true
      else
        debug_print "Could not open #{ dir }, skipping\n"
        return false
      end 
    end

    end
  end
end


