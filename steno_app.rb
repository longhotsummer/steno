require 'sinatra'
require 'sinatra/assetpack'
require 'padrino-helpers'

$:.unshift(File.join(File.dirname(__FILE__), 'lib'))
require 'steno/document'

class StenoApp < Sinatra::Base
  set :root, File.dirname(__FILE__)
  set :haml, format: :html5
  set :protect_from_csrf, false

  register Padrino::Helpers
  register Sinatra::AssetPack

  assets do
    js :app, [
      '/js/app.js',
    ]

    css :app, [
      '/css/app.css'
    ]
  end
  

  get "/" do
    haml :index
  end

  post "/parse" do
    doc = Steno::Document.new(params[:doc])

    doc.parse!
    doc.render! if doc.validates?

    content_type "application/json"
    return doc.to_json
  end
end
