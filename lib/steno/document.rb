require 'json'
require 'time'
require 'nokogiri'

require 'slaw'

module Steno
  class Metadata
    attr_accessor :short_name

    attr_accessor :region
    attr_accessor :pub_date

    FIELDS = %w(short_name pub_date region)

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

    def uri
      "/za/by-law/#{@region || 'region'}/#{year || 'year'}/#{@short_name}"
    end
  end

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

    def apply_metadata(metadata)
      for component, xpath in [['main',      '//a:act/a:meta/a:identification'],
                               ['schedules', '//a:component/a:doc/a:meta/a:identification']] do
        ident = xml_doc.at_xpath(xpath, a: NS)
        next if not ident

        # work
        ident.at_xpath('a:FRBRWork/a:FRBRthis', a: NS)['value'] = "#{metadata.uri}/#{component}"
        ident.at_xpath('a:FRBRWork/a:FRBRuri', a: NS)['value'] = metadata.uri

        # expression
        ident.at_xpath('a:FRBRExpression/a:FRBRthis', a: NS)['value'] = "#{metadata.uri}/#{component}/eng@"
        ident.at_xpath('a:FRBRExpression/a:FRBRuri', a: NS)['value'] = "#{metadata.uri}/eng@"

        # manifestation
        ident.at_xpath('a:FRBRManifestation/a:FRBRthis', a: NS)['value'] = "#{metadata.uri}/#{component}/eng@"
        ident.at_xpath('a:FRBRManifestation/a:FRBRuri', a: NS)['value'] = "#{metadata.uri}/eng@"
      end

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
