require 'json'
require 'time'
require 'logging'

require 'slaw/parse/akoma_ntoso_builder'
require 'slaw/parse/parser'
require 'slaw/render/transforms'

require 'steno/document'
require 'steno/region'

module Steno
  class Metadata
    attr_accessor :title
    attr_accessor :short_name

    attr_accessor :region

    attr_accessor :pub_name
    attr_accessor :pub_number
    attr_accessor :pub_date

    FIELDS = %w(title short_name pub_name pub_number pub_date region)

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
      "/za/by-law/#{@region || 'region'}/#{year || 'year'}/#{@short_name}"
    end
  end

  class DocumentParser
    include Logging

    attr_accessor :metadata
    attr_reader :source_text
    attr_reader :parse_errors
    attr_accessor :options

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

      parser = Slaw::Parse::Parser.new
      parser.options = @options || {}
      begin
        tree = parser.parse_bylaw(@source_text, root)

        # transform the AST into AkomaNtoso XML
        xml = builder.xml_from_syntax_tree(tree)
      rescue Slaw::Parse::ParseError => e
        @parse_errors << e
        return nil
      end

      doc = Steno::Document.new
      doc.xml_doc = builder.parse_xml(xml)

      postprocess(doc.xml_doc)

      doc.source_text = @source_text
      doc.apply_metadata(@metadata) if @metadata

      doc
    end

    # Clean up the source text
    def preprocess(source_text)
      builder.preprocess(source_text)
    end

    # post-process the XML
    def postprocess(doc)
      logger.info("Postprocessing xml...")

      builder.postprocess(doc)
    end

    protected

    def builder
      @builder ||= Slaw::Parse::AkomaNtosoBuilder.new
    end
  end
end
