require 'sinatra'
require 'sinatra/assetpack'
require 'padrino-helpers'

class StenoApp < Sinatra::Base
  set :root, File.dirname(__FILE__)
  set :haml, format: :html5

  register Padrino::Helpers
  register Sinatra::AssetPack

  assets do
    # The second parameter defines where the compressed version will be served.
    # (Note: that parameter is optional, AssetPack will figure it out.)
    # The final parameter is an array of glob patterns defining the contents
    # of the package (as matched on the public URIs, not the filesystem)
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

  post "/by-law/parse" do
    doc = params[:doc]

    parser = ByLawParser.new
    if parser.parse!(doc.source_text)
      parser.validate!
    end

    content_type "application/json"
    {
      "source_text" => parser.source_text,
      "xml" => parser.xml,
      "metadata" => parser.metadata,
      "validates" => parser.validates,
      "parse_errors" => parser.parse_errors,
      "validation_errors" => parser.validation_errors,
    }.to_json
  end
end
