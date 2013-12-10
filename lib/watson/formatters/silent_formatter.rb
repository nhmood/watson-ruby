module Watson::Formatters
  # [review] - All other formatters inherit from BaseFormatter
  # but since the only thing silent does differently is not print
  # the results, inheriting from DefaultFormatter simplifies things
  # We don't have to worry about cprint/print_status/ect
  class SilentFormatter < DefaultFormatter
    def run(structure)
    end
  end
end
