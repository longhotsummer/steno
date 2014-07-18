require 'open3'

require 'logging'

module Steno
  class Importer
    include Logging

    def import_from_upload(mimetype, file)
      case mimetype
      when "text/plain"
        file.read()
      when "application/pdf"
        import_from_pdf(file)
      end
    end

    def import_from_pdf(file)
      cmd = "#{Importer.pdftotext_path} -enc UTF-8 #{file.path} -"
      logger.info("Executing: #{cmd}")
      stdout, status = Open3.capture2(cmd)

      if status == 0
        pdf_post_cleanup(stdout)
      else
        nil
      end
    end

    def pdf_post_cleanup(text)
      # do general once-off cleanup on pdf output

      # (1) foo; (2) bar
      text.gsub!(/; \(/, ";\n(")

      text
    end

    def self.pdftotext_path
      @@pdftotext_path
    end

    def self.pdftotext_path=(val)
      @@pdftotext_path = val
    end

    def self.set_defaults
      bin = case RUBY_PLATFORM
            when /darwin/
              "pdftotext-mac"
            else
              "pdftotext"
            end
      path = File.expand_path('../../bin/', File.dirname(__FILE__))
      self.pdftotext_path = File.join(path, bin)
    end

    self.set_defaults
  end
end
