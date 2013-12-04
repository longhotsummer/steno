require 'json'
require 'time'

require 'logging'

require 'slaw/namespaces'
require 'slaw/parse/akoma_ntoso_builder'
require 'slaw/render/transforms'

module Steno
  class Document
    include Logging
    include Slaw::Namespaces

    attr_accessor :source_text
    attr_accessor :xml

    attr_reader :validate_errors

    def initialize
    end

    def validate!
      @validate_errors = []

      # TODO: validate XML
      # TODO: error handling
      @valid = true
    end

    def validates?
      validate! if @valid.nil?

      @valid
    end

    def apply_metadata(metadata)
      doc = builder.parse_xml(xml)

      ident = doc.at_xpath('//a:act/a:meta/a:identification', a: AN)

      # work
      ident.at_xpath('a:FRBRWork/a:FRBRthis', a: AN)['value'] = "#{metadata.uri}/main"
      ident.at_xpath('a:FRBRWork/a:FRBRuri', a: AN)['value'] = metadata.uri
      ident.at_xpath('a:FRBRWork/a:FRBRalias', a: AN)['value'] = metadata.title
      ident.at_xpath('a:FRBRWork/a:FRBRdate', a: AN)['date'] = metadata.date

      # expression
      ident.at_xpath('a:FRBRExpression/a:FRBRthis', a: AN)['value'] = "#{metadata.uri}/main/eng@"
      ident.at_xpath('a:FRBRExpression/a:FRBRuri', a: AN)['value'] = "#{metadata.uri}/eng@"
      ident.at_xpath('a:FRBRExpression/a:FRBRdate', a: AN)['date'] = metadata.date

      # manifestation
      ident.at_xpath('a:FRBRManifestation/a:FRBRthis', a: AN)['value'] = "#{metadata.uri}/main/eng@"
      ident.at_xpath('a:FRBRManifestation/a:FRBRuri', a: AN)['value'] = "#{metadata.uri}/eng@"

      # publication info
      pub = doc.at_xpath('//a:act/a:meta/a:publication', a: AN)
      pub["number"] = metadata.pub_number
      pub["showAs"] = pub["name"] = metadata.pub_name
      pub["date"] = metadata.date

      # council
      council = doc.at_css('#council')
      council['href'] = "/ontology/organization/za/council.#{metadata.region}"

      if region = Steno::Region.for_code(metadata.region)
        council['showAs'] = region.council
      end

      self.xml = builder.to_xml(doc)
    end

    def render
      xml.present? ? Slaw::Render::Transforms.new.act_to_html(builder.parse_xml(xml), '/root/') : nil
    end

    def render_toc
      # XXX
      "TODO"
    end

    protected

    def builder
      @builder ||= Slaw::Parse::AkomaNtosoBuilder.new
    end
  end
end
