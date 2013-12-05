require 'json'

module Watson::Formatters
  class JsonFormatter < BaseFormatter
    def run(structure)
      debug_print "#{self} : #{__method__}\n"

      File.open(@config.tmp_file, 'w') do |f|
        f.write(structure.to_json)
      end
    end
  end
end
