require 'treetop'

require 'slaw/parse/syntax/act'
require 'slaw/parse/syntax/bylaw'

module Slaw
  module Parse
    class Parser
      Treetop.load(File.dirname(__FILE__) + "/grammar/act.treetop")
      Treetop.load(File.dirname(__FILE__) + "/grammar/bylaw.treetop")

      attr_accessor :options

      def parse_act(source)
        parser = ActParser.new
        parser.options = options

        tree = parser.parse(source)

        error_from_parser(parser) if tree.nil?

        tree
      end

      def parse_definitions(source, opts={})
        parser = BylawParser.new
        parser.options = options

        opts[:root] = :definitions_section

        tree = parser.parse(source, opts)

        error_from_parser(parser) if tree.nil?

        tree
      end

      def parse_bylaw(source, root=:bylaw, opts={})
        parser = BylawParser.new
        parser.options = options

        opts[:root] = root

        tree = parser.parse(source, opts)

        error_from_parser(parser) if tree.nil?

        tree
      end

      def error_from_parser(parser)
        raise Slaw::Parse::ParseError.new(parser.failure_reason || "Couldn't match to grammar",
                                          line: parser.failure_line || 0,
                                          column: parser.failure_column || 0)
      end
    end

    class ParseError < Exception
      attr_accessor :line, :column

      def initialize(message, opts)
        super(message)

        self.line = opts[:line]
        self.column = opts[:column]
      end

      # TODO: move this elsewhere, it's out of context here
      def to_json(g=nil)
        msg = self.message
        msg = msg[0..200] + '...' if msg.length > 200

        {
          message: msg,
          line: self.line,
          column: self.column,
        }.to_json(g)
      end
    end
  end
end
