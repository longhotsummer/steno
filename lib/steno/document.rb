require 'json'
require 'time'

require 'logging'
require 'steno/akoma_ntoso_builder'
require 'steno/parser'

module Steno
  class Metadata
    attr_accessor :title
    attr_accessor :short_name

    attr_accessor :pub_name
    attr_accessor :pub_number
    attr_accessor :pub_date

    FIELDS = %w(title short_name pub_name pub_number pub_date)

    def initialize(hash=nil)
      # load values from hash
      if hash
        FIELDS.each do |attr|
          self.send("#{attr}=", hash[attr]) if hash[attr]
        end

        self.pub_date = Time.parse(pub_date) if pub_date.present?
      end
    end
  end

  class Document
    include Logging

    attr_accessor :source_text
    attr_accessor :xml
    attr_accessor :html

    attr_reader :parse_errors
    attr_reader :validate_errors

    def initialize(hash=nil)
      if hash
        @meta = Metadata.new(hash["meta"]) if hash["meta"]

        @source_text = hash["source_text"]
        @xml = hash["xml"]
      end
    end

    # Clean up the source text
    def preprocess!
      self.source_text = builder.preprocess(source_text)
    end

    # Parse the plain text source into XML, validate and post-process it.
    # Returns true if successful, false if there were errors.
    def parse!
      @parse_errors = []
      @xml = nil

      preprocess!

      root = :bylaw
      logger.info("Parsing #{root}...")

      parser = Steno::Parser.new
      begin
        tree = parser.parse_bylaw(source_text, root)

        # transform the AST into AkomaNtoso XML
        self.xml = builder.xml_from_syntax_tree(tree)
      rescue Steno::ParseError => e
        @parse_errors << e
        return false
      end

      return false unless validate!

      postprocess!

      true
    end

    # post-process the XML
    def postprocess!
      logger.info("Postprocessing xml...")

      self.xml = builder.postprocess(xml)

      apply_metadata! if @meta
    end

    def validate!
      @validate_errors = []

      # TODO: validate XML
      # TODO: error handling
      @valid = true
    end

    def validates?
      validate!  if @valid.nil?

      @valid
    end

    def apply_metadata!
      doc = builder.parse_xml(xml)

      doc.at_xpath('//a:act/a:meta/a:identification/a:FRBRWork/a:FRBRalias', a: Steno::AN)['value'] = \
        @meta.title if @meta.title.present?

      # TODO: other metadata

      self.xml = builder.to_xml(doc)
    end

    def render!
      # TODO: transform to html
    end

    def to_json
      {
        "source_text" => source_text,
        "html" => html,
        "xml" => xml,
        "parse_errors" => parse_errors,
        "validate_errors" => validate_errors
      }.to_json
    end

    protected

    def builder
      @builder ||= Steno::AkomaNtosoBuilder.new
    end
  end
end
