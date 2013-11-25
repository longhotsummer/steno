require 'json'
require 'time'

require 'logging'
require 'steno/akoma_ntoso_builder'
require 'steno/parser'
require 'steno/transforms'

module Steno
  class Document
    include Logging

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

      ident = doc.at_xpath('//a:act/a:meta/a:identification', a: Steno::AN)

      # work
      ident.at_xpath('a:FRBRWork/a:FRBRthis', a: Steno::AN)['value'] = "#{metadata.uri}/main"
      ident.at_xpath('a:FRBRWork/a:FRBRuri', a: Steno::AN)['value'] = metadata.uri
      ident.at_xpath('a:FRBRWork/a:FRBRalias', a: Steno::AN)['value'] = metadata.title
      ident.at_xpath('a:FRBRWork/a:FRBRdate', a: Steno::AN)['date'] = metadata.date

      # expression
      ident.at_xpath('a:FRBRExpression/a:FRBRthis', a: Steno::AN)['value'] = "#{metadata.uri}/main/eng@"
      ident.at_xpath('a:FRBRExpression/a:FRBRuri', a: Steno::AN)['value'] = "#{metadata.uri}/eng@"
      ident.at_xpath('a:FRBRExpression/a:FRBRdate', a: Steno::AN)['date'] = metadata.date

      # manifestation
      ident.at_xpath('a:FRBRManifestation/a:FRBRthis', a: Steno::AN)['value'] = "#{metadata.uri}/main/eng@"
      ident.at_xpath('a:FRBRManifestation/a:FRBRuri', a: Steno::AN)['value'] = "#{metadata.uri}/eng@"

      # publication info
      pub = doc.at_xpath('//a:act/a:meta/a:publication', a: Steno::AN)
      pub["number"] = metadata.pub_number
      pub["showAs"] = pub["name"] = metadata.pub_name
      pub["date"] = metadata.date

      self.xml = builder.to_xml(doc)
    end

    def render
      xml.present? ? Steno::Transforms.new.act_to_html(builder.parse_xml(xml), '/root/') : nil
    end

    def render_toc
      # XXX
      "TODO"
    end

    protected

    def builder
      @builder ||= Steno::AkomaNtosoBuilder.new
    end
  end
end
