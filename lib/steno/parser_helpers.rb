module Steno
  module ParserHelpers
    attr_writer :options

    def options
      @options ||= {}
    end
  end
end
