require 'elasticsearch'
require 'log4r'

module Steno
  # Support for indexing and search using elasticsearch
  class ElasticSearchSupport
    attr_accessor :es, :mapping, :index, :type, :base_url

    include Slaw::Logging

    def initialize(index, type, base_url, client_params={}, es=nil)
      @es = es || create_client(client_params)

      @ix = index
      @type = type
      @base_url = base_url

      @mapping = {
        frbr_uri:     {type: 'string', index: 'not_analyzed'},
        url:          {type: 'string', index: 'not_analyzed'},
        title:        {type: 'string', analyzer: 'english', index_options: 'offsets'},
        content:      {type: 'string', analyzer: 'english', index_options: 'offsets'},
        published_on: {type: 'date', format: 'dateOptionalTime'},
        region:       {type: 'string', index: 'not_analyzed'},
        region_name:  {type: 'string', index: 'not_analyzed'},
        repealed:     {type: 'boolean'},
      }
    end

    def create_client(client_params)
      Elasticsearch::Client.new(client_params)
    end

    def reindex!(docs, &block)
      index_documents!(docs, &block)
    end

    def index_documents!(docs, &block)
      logger.info("Indexing #{docs.length} bylaws...")

      for doc in docs
        id = doc.id_uri.gsub('/', '-')

        data = {
          frbr_uri: doc.id_uri,
          url: @base_url + doc.id_uri,
          title: doc.title,
          content: doc.body.text,
          region: doc.region,
          published_on: doc.publication['date'],
          repealed: doc.repealed?,
        }

        yield doc, data if block_given?

        logger.info("Indexing #{id}")
        @es.index(index: @ix, type: @type, id: id, body: data)
      end

      logger.info("Indexing complete")
    end

    def define_mapping!
      logger.info("Deleting index")
      @es.indices.create(index: @ix) unless @es.indices.exists(index: @ix)

      # delete existing mapping
      unless @es.indices.get_mapping(index: @ix, type: @type).empty?
        @es.indices.delete_mapping(index: @ix, type: @type) 
      end

      logger.info("Defining mappings")
      @es.indices.put_mapping(index: @ix, type: @type, body: {
        @type => {properties: @mapping}
      })
    end

    def search(q, from=0, size=10, region_name=nil)
      filters = {}
      filters = {term: {region_name: region_name}} if region_name and not region_name.empty?

      # We do two queries, one is a general term query across the fields,
      # the other is a phrase query. At the very least, items *must*
      # match the term search, and items are preferred if they
      # also match the phrase search.
      query = {
        bool: {
          must: {
            # best across all the fields
            multi_match: {
              query: q,
              type: 'best_fields',
              fields: ['title', 'content'],
              # this helps skip stopwords, see
              # http://www.elasticsearch.org/blog/stop-stopping-stop-words-a-look-at-common-terms-query/
              cutoff_frequency: 0.0007,
              operator: 'and',
            },
          },
          should: {
            # try to match to a phrase
            multi_match: {
              query: q,
              fields: ['title', 'content'],
              type: 'phrase',
            },
          },
        }
      }

      @es.search(index: @ix, body: {
        query: query,
        fields: ['frbr_uri', 'repealed', 'published_on', 'title', 'url', 'region_name', 'region'],
        from: from,
        size: size,
        sort: {'_score' => {order: 'desc'}},
        # filter after searching so filtering doesn't impact aggs
        post_filter: filters,
        # count by region name
        aggs: {region_names: {terms: {field: 'region_name'}}},
        highlight: {
          pre_tags: ['<mark>'],
          post_tags: ['</mark>'],
          order: "score",
          no_match_size: 0,
          fields: {
            content: {
              number_of_fragments: 1,
            },
            title: {
              number_of_fragments: 0, # entire field
            }
          },
        },
      })
    end
  end
end
