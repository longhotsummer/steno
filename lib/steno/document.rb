require 'json'
require 'time'
require 'nokogiri'

require 'slaw'

module Steno
  class Document
    include Slaw::Logging
    include Slaw::Namespace

    attr_accessor :source_text

    # A Nokogiri XML document
    attr_accessor :xml_doc

    attr_reader :validate_errors

    def initialize
    end

    def validate!
      @validate_errors = []

      schema = Dir.chdir(File.dirname(__FILE__) + "/../schemas") { Nokogiri::XML::Schema(File.read('akomantoso20.xsd')) }
      errors = schema.validate(xml_doc)

      @validate_errors = errors.map do |e|
        {
          message: e.to_s,
          line: e.line,
          column: e.column,
        }
      end

      @valid = @validate_errors.empty?
    end

    def validates?
      validate! if @valid.nil?

      @valid
    end

    # Re-run post-processing on this document
    def postprocess!
      builder.sanitise(xml_doc)
    end

    def render
      xml_doc && Slaw::Render::HTMLRenderer.new.render(xml_doc, '/root/')
    end

    # Serialise the XML for this document
    def xml
      xml_doc.to_xml(indent: 2)
    end

    # Set the XML for this document. This will parse
    # the document using Nokogiri.
    def xml=(xml)
      self.xml_doc = Nokogiri::XML(xml, &:noblanks)
    end

    protected
    def builder
      @builder ||= Slaw::Parse::Builder.new
    end
  end
end
