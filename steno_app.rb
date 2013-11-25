require 'sinatra'
require 'sinatra/assetpack'
require 'padrino-helpers'
require 'log4r'

# Setup logging
log = Log4r::Logger.new('Steno')
log.add Log4r::StderrOutputter.new('stderr')
log.outputters.last.formatter = Log4r::PatternFormatter.new(pattern: '%d %c %m')

$:.unshift(File.join(File.dirname(__FILE__), 'lib'))
require 'steno/document'
require 'steno/document_parser'

class StenoApp < Sinatra::Base
  set :root, File.dirname(__FILE__)
  set :haml, format: :html5

  disable :protect_from_csrf
  enable :logging

  register Padrino::Helpers
  register Sinatra::AssetPack

  assets do
    js :app, [
      '/js/app.js',
    ]

    css :app, [
      '/css/act.css',
      '/css/app.css',
    ]
  end
  

  get "/" do
    haml :index
  end

  post "/parse" do
    parser = Steno::DocumentParser.new
    parser.metadata = Steno::Metadata.new(params[:doc][:meta])
    doc = parser.parse(params[:doc][:source_text])

    content_type "application/json"
    {
      "source_text" => parser.source_text,
      "parse_errors" => parser.parse_errors,
      "xml" => doc ? doc.xml : nil,
    }.to_json
  end

  post "/render" do
    doc = Steno::Document.new
    doc.xml = (params[:doc] || {})[:xml]

    content_type "application/json"
    {
      "html" => doc.render,
      "toc"  => doc.render_toc
    }.to_json
  end

  post "/validate" do
    doc = Steno::Document.new
    doc.xml = params[:doc][:xml]

    doc.validate!

    content_type "application/json"
    {
      "validation_errors" => doc.validation_errors,
      "validates" => doc.validates?
    }.to_json
  end
end
