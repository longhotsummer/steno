require 'open3'

module Steno
  class Importer
    def import_from_upload(mimetype, file)
      case mimetype
      when "text/plain"
        file.read()
      when "application/pdf"
        import_from_pdf(file)
      end
    end

    def import_from_pdf(file)
      data = file.read()
      stdout, status = Open3.capture2('pdftotext - -', stdin_data: data)

      status == 0 ? stdout : nil
    end
  end
end
