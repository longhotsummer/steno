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
    doc = Steno::Document.new(params[:doc])

    doc.parse!
    doc.render!

    content_type "application/json"
    return doc.to_json
  end
end
