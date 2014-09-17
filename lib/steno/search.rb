require 'steno/elasticsearch'

module Steno
  class Search
    ELASTICSEARCH_PARAMS = [
      'openbylaws.org.za',         # index
      'bylaw',                     # type
      'http://openbylaws.org.za',  # base url
      {
        url: ENV['BONSAI_URL'] || 'http://localhost:9200',
        reload_on_failure: true,
      }
    ]

    def self.searcher
      @@searcher ||= Steno::ElasticSearchSupport.new(*ELASTICSEARCH_PARAMS)
    end
  end
end
