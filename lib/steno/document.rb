require 'json'
require 'time'
require 'nokogiri'

require 'logging'

require 'slaw/namespaces'
require 'slaw/render/transforms'

module Steno
  class Document
    include Logging
    include Slaw::Namespaces

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

    def apply_metadata(metadata)
      for component, xpath in [['main',      '//a:act/a:meta/a:identification'],
                               ['schedules', '//a:component/a:doc/a:meta/a:identification']] do
        ident = xml_doc.at_xpath(xpath, a: AN)
        next if not ident

        # work
        ident.at_xpath('a:FRBRWork/a:FRBRthis', a: AN)['value'] = "#{metadata.uri}/#{component}"
        ident.at_xpath('a:FRBRWork/a:FRBRuri', a: AN)['value'] = metadata.uri
        ident.at_xpath('a:FRBRWork/a:FRBRdate', a: AN)['date'] = metadata.date
        if component == 'main'
          ident.at_xpath('a:FRBRWork/a:FRBRalias', a: AN)['value'] = metadata.title
        end

        # expression
        ident.at_xpath('a:FRBRExpression/a:FRBRthis', a: AN)['value'] = "#{metadata.uri}/#{component}/eng@"
        ident.at_xpath('a:FRBRExpression/a:FRBRuri', a: AN)['value'] = "#{metadata.uri}/eng@"
        ident.at_xpath('a:FRBRExpression/a:FRBRdate', a: AN)['date'] = metadata.date

        # manifestation
        ident.at_xpath('a:FRBRManifestation/a:FRBRthis', a: AN)['value'] = "#{metadata.uri}/#{component}/eng@"
        ident.at_xpath('a:FRBRManifestation/a:FRBRuri', a: AN)['value'] = "#{metadata.uri}/eng@"
      end

      # publication info
      pub = xml_doc.at_xpath('//a:act/a:meta/a:publication', a: AN)
      pub["number"] = metadata.pub_number
      pub["showAs"] = pub["name"] = metadata.pub_name
      pub["date"] = metadata.date

      # council
      council = xml_doc.at_css('#council')
      council['href'] = "/ontology/organization/za/council.#{metadata.region}"

      if region = Steno::Region.for_code(metadata.region)
        council['showAs'] = region.council
      end
    end

    # Re-run post-processing on this document
    def postprocess!
      builder.sanitise(xml_doc)
    end

    def render
      xml_doc && Slaw::Render::HTMLRenderer.new.render_bylaw(xml_doc, '/root/')
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
      @builder ||= Slaw::Parse::AkomaNtosoBuilder.new
    end
  end
end
