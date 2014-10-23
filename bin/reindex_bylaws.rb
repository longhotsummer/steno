#!/usr/bin/env ruby

require 'json'
require 'log4r'
require 'slaw'

outputter = Log4r::StderrOutputter.new('stderr')
outputter.formatter = Log4r::PatternFormatter.new(pattern: '%d %c %m')
Log4r::Logger.new('Slaw').add(outputter)
Log4r::Logger.new('Steno').add(outputter)

$:.unshift(File.join(File.dirname(__FILE__), '../lib'))
require 'steno/search'

unless ENV['BONSAI_URL']
  puts "WARNING: The env variable BONSAI_URL is not set, indexing to local Elasticsearch."
  puts "         You probably want to set BONSAI_URL, check heroku config | fgrep BONSAI"
end

regions = File.open('../za-by-laws/regions/regions.json') { |f| JSON.load(f) }
searcher = Steno::Search.searcher

if ARGV.empty?
  bylaws = Slaw::DocumentCollection.new
  bylaws.discover('../za-by-laws/by-laws/', Slaw::ByLaw)
  remap = true
else
  bylaws = ARGV.map { |fname| b = Slaw::ByLaw.new; b.load(fname); b }
  remap = false
end

# only do this if we're doing the whole set, since it cleans out the
# existing index
searcher.define_mapping! if remap

searcher.reindex!(bylaws) do |doc, hash|
  hash['region_name'] = regions[doc.region]['name']
end

puts "Reindexed #{bylaws.length} bylaws"
