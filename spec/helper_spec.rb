# [review] - Using own funky path loading because traditional way seems wrong?
# Commented out version is traditional, seen in many apps. If you use that and
# look at load_path you get path/../lib (I'd expect those to be separate?)
# My funky version adds path/., path/bin, path/assets separately
# Maybe I don't get how the load path is supposed to look though...

#$:.unshift File.join(File.dirname(__FILE__), *%w[.. lib])
$:.unshift *%w[. assets lib].map { |m| __dir__.gsub(/\/test(.?)+/, '') + '/' + m }
#p($:)

require 'watson'


def silence_output
  # Store the original stderr and stdout in order to restore them later
  @original_stderr = $stderr
  @original_stdout = $stdout

  # Redirect stderr and stdout
  $stderr = File.new(File.join(__dir__, 'null.txt'), 'w')
  $stdout = File.new(File.join(__dir__, 'null.txt'), 'w')
end


def enable_output
  $stderr = @original_stderr
  $stdout = @original_stdout
  @original_stderr = nil
  @original_stdout = nil

  File.delete(File.join(__dir__, 'null.txt'))
end
