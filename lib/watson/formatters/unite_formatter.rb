require 'json'

module Watson::Formatters
  class UniteFormatter < BaseFormatter
    def run(structure)
      debug_print "#{self} : #{__method__}\n"

      candidates = generate_candidates(structure)

      File.open(@config.tmp_file, 'w') do |f|
        f.write(candidates.to_json)
      end
    end

    private

    def generate_candidates(structure)
      candidates = []

      structure[:files].each do |file|
        original_candidate = {
          action__path: file[:absolute_path],
          action__absolute_path: file[:absolute_path],
          action__relative_path: file[:relative_path],
          is_multiline: 1,
          action__has_issue: file[:has_issues] ? 1 : 0,
          action__tags: @config.tag_list,
        }

        if file[:has_issues]
          @config.tag_list.each do |tag|
            file[tag].each do |info|
              candidates << original_candidate.dup.merge(create_candidate(file, info))
            end
          end
        else
          original_candidate[:word] = "[o] #{file[:relative_path]}"
          candidates << original_candidate
        end
      end

      structure[:subdirs].each do |dir|
        candidates += generate_candidates(dir)
      end

      candidates
    end

    def create_candidate(file, info)
      {
        word: "[x] #{file[:relative_path]}:#{info[:line_number]}\n    #{info[:tag]} - #{info[:title]}",
        action__line: info[:line_number],
        action__tag: info[:tag],
        action__md5: info[:md5],
        action__title: info[:title],
        action__context: info[:context],
      }
    end
  end
end
