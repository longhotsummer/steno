#!/usr/bin/env ruby

# add frbr_uri field
# add url field
# host search behind steno api, or behind a new api
# need to run elasticsearch server somewhere
#   - as a docker, global for all c4sa projects

require 'elasticsearch'

# TODO: HACK
$:.unshift('../web/lib')
require 'by_law'

class Indexer
  def initialize()
    @es = Elasticsearch::Client.new(log: true)
    @es.transport.reload_connections!

    @ix = 'openbylaws.org.za'
    @type = 'bylaw'
  end

  def reindex
    define_mapping
    add_bylaws
  end

  def define_mapping
    @es.indices.delete_mapping(index: @ix, type: @type)
    @es.indices.put_mapping(index: @ix, type: @type, body: {
      bylaw: {
        properties: {
          frbr_uri: {type: 'string', index: 'not_analyzed'},
          url: {type: 'string', index: 'not_analyzed'},
          title: {type: 'string', analyzer: 'english'},
          content: {type: 'string', analyzer: 'english'},
          published_on: {type: 'date', format: 'dateOptionalTime'},
          region: {type: 'string', index: 'not_analyzed'},
          region_name: {type: 'string', index: 'not_analyzed'},
          repealed: {type: 'boolean'},
        }
      }
    })
  end

  def add_bylaws
    bylaws = AkomaNtoso::ByLaw.discover('../za-by-laws/by-laws/')

    for bylaw in bylaws
      id = bylaw.id_uri.gsub('/', '-')
      region = bylaw.region.gsub('-', ' ').split.map(&:capitalize).join(' ')

      @es.index(index: @ix, type: @type, id: id, body: {
        frbr_uri: bylaw.id_uri,
        url: "http://openbylaws.org.za#{bylaw.id_uri}",
        title: bylaw.short_title,
        content: bylaw.body.text,
        region: bylaw.region,
        region_name: region,
        published_on: bylaw.publication['date'],
        repealed: bylaw.repealed?,
      })
    end

    print "Reindexed #{bylaws.length} bylaws"
  end
end

Indexer.new.reindex
