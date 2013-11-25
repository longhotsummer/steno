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
      ident.at_xpath('a:FRBRWork/a:FRBRalias', a: Steno::AN)['value'] = metadata.title

      doc.at_xpath('//a:act/a:meta/a:identification/a:FRBRWork/a:FRBRthis', a: Steno::AN)['value'] = metadata.uri
      doc.at_xpath('//a:act/a:meta/a:identification/a:FRBRWork/a:FRBRuri', a: Steno::AN)['value'] = "#{metadata.uri}/main"

      pub = doc.at_xpath('//a:act/a:meta/a:publication', a: Steno::AN)
      pub["number"] = metadata.pub_number
      pub["showAs"] = pub["name"] = metadata.pub_name
      pub["date"] = metadata.date


      # TODO: other metadata

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
