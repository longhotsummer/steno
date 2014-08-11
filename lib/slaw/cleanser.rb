# encoding: utf-8

module Slaw
  # Helper class to run various cleanup routines on plain text.
  #
  # Some of these routines can safely be run multiple times,
  # others are meant to be run only once.
  class Cleanser

    # Run general cleanup, such as stripping bad chars and
    # removing unnecessary whitespace. This is idempotent
    # and safe to run multiple times.
    def cleanup(s)
      s = scrub(s)
      s = correct_newlines(s)
      s = fix_quotes(s)
      s = expand_tabs(s)
      s = chomp(s)
      s = enforce_newline(s)
      s = remove_boilerplate(s)
    end

    # Run deeper introspections and reformat the text, such as
    # unwrapping/re-wrapping lines. These may not be safe to run
    # multiple times.
    def reformat(s)
      s = unbreak_lines(s)
      s = break_lines(s)
      s = enforce_newline(s)
    end

    # ------------------------------------------------------------------------

    # line endings
    def correct_newlines(s)
      s.gsub(/\r\n/, "\n")\
       .gsub(/\r/, "\n")
    end

    # strip invalid bytes and ones we don't like
    def scrub(s)
      # we often get this unicode codepoint in the string, nuke it
      s.gsub([65532].pack('U*'), '')\
       .gsub("", '')
    end

    def fix_quotes(s)
      # change weird quotes to normal ones
      s.gsub(/‘‘|’’|''/, '"')
    end

    def expand_tabs(s)
      # tabs to spaces
      s.gsub(/\t/, ' ')
    end

    def remove_boilerplate(s)
      # nuke any line to do with Sabinet and the government printer
      s.gsub(/^.*Sabinet.*Government Printer.*$/i, '')\
       .gsub(/^.*Provincial Gazette \d+.*$/i, '')\
       .gsub(/^.*Provinsiale Koerant \d+.*$/i, '')\
       .gsub(/^\s*\d+\s*$/, '')\
      # get rid of date lines
       .gsub(/^\d+\s+\w+\s+\d+$/, '')\
      # get rid of page number lines
       .gsub(/^\s*page \d+( of \d+)?\s*\n/i, '')
    end

    def chomp(s)
      # trailing whitespace at end of lines
      s = s.gsub(/ +$/, '')

      # whitespace on either side
      s.strip
    end

    def enforce_newline(s)
      # ensure string ends with a newline
      s.end_with?("\n") ? s : (s + "\n")
    end

    # make educated guesses about lines that should
    # have been broken but haven't, and break them
    def break_lines(s)
      # often we find a section title munged onto the same line as its first statement
      # eg:
      # foo bar. New section title 62. (1) For the purpose
      s = s.gsub(/\. ([^.]+) (\d+\. \(1\) )/, ".\n" + '\1' + "\n" + '\2')

      # New section title 62. (1) For the purpose
      s = s.gsub(/(\w) (\d+\. \(1\) )/, '\1' + "\n" + '\2')

      # (1) foo; (2) bar
      s = s.gsub(/; \(/, ";\n(")

      # (1) foo; and (2) bar
      # (1) foo; or (2) bar
      s = s.gsub(/; (and|or) \(/, "; \\1\n(")

      # "foo" means ...; "bar" means
      s = s.gsub(/; (["”“][^"”“]+?["”“] means)/, ";\n\\1")

      s
    end

    # finds likely candidates for unnecessarily broken lines
    # and  them
    def unbreak_lines(s)
      lines = s.split(/\n/)
      output = []
      start_re = /^\s*[a-z]/
      end_re   = /[a-z0-9]\s*$/

      prev = nil
      lines.each_with_index do |line, i|
        if i == 0
          output << line
        else
          prev = output[-1]

          if line =~ start_re and prev =~ end_re
            output[-1] = prev + ' ' + line
          else
            output << line
          end
        end
      end

      output.join("\n")
    end
  end
end
