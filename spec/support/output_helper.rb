module OutputHelper
  TEMP = File.join(__dir__, 'null.txt')

  def silence_output
    # Store the original stderr and stdout in order to restore them later
    @original_stderr = $stderr
    @original_stdout = $stdout

    # Redirect stderr and stdout
    $stderr = $stdout = File.new(TEMP, 'w')
  end

  def enable_output
    $stderr = @original_stderr
    $stdout = @original_stdout
    @original_stderr = nil
    @original_stdout = nil

    File.delete(TEMP) if File.exists?(TEMP)
  end
end
