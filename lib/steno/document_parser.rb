require 'json'
require 'time'

require 'logging'
require 'steno/akoma_ntoso_builder'
require 'steno/parser'
require 'steno/transforms'

module Steno
  class Metadata
    attr_accessor :title
    attr_accessor :short_name

    attr_accessor :locale

    attr_accessor :pub_name
    attr_accessor :pub_number
    attr_accessor :pub_date

    FIELDS = %w(title short_name pub_name pub_number pub_date locale)

    def initialize(hash=nil)
      # load values from hash
      if hash
        FIELDS.each do |attr|
          self.send("#{attr}=", hash[attr]) if hash[attr]
        end

        self.pub_date = Time.parse(pub_date) if pub_date.present?
      end
    end
  
    def year
      pub_date && pub_date.strftime('%Y')
    end

    def date
      pub_date && pub_date.strftime('%Y-%m-%d')
    end

    def uri
      "/za/by-law/#{@locale || 'locale'}/#{year || 'year'}/#{@short_name}"
    end
  end

  class DocumentParser
    include Logging

    attr_accessor :metadata
    attr_reader :source_text
    attr_reader :parse_errors

    def initialize
    end

    # Parse the plain text source into XML.
    # Returns a Steno::Document instance if successful, nil if there were errors.
    def parse(source_text)
      @source_text = source_text
      @parse_errors = []

      @source_text = preprocess(@source_text)

      root = :bylaw
      logger.info("Parsing #{root}...")

      parser = Steno::Parser.new
      begin
        tree = parser.parse_bylaw(@source_text, root)

        # transform the AST into AkomaNtoso XML
        xml = builder.xml_from_syntax_tree(tree)
      rescue Steno::ParseError => e
        @parse_errors << e
        return nil
      end

      xml = postprocess(xml)

      doc = Steno::Document.new
      doc.source_text = @source_text
      doc.xml = xml
      doc.apply_metadata(@metadata) if @metadata

      doc
    end

    # Clean up the source text
    def preprocess(source_text)
      builder.preprocess(source_text)
    end

    # post-process the XML
    def postprocess(xml)
      logger.info("Postprocessing xml...")

      builder.postprocess(xml)
    end

    def validate
      @validate_errors = []

      # TODO: validate XML
      # TODO: error handling
      @valid = true
    end

    protected

    def builder
      @builder ||= Steno::AkomaNtosoBuilder.new
    end
  end
end
