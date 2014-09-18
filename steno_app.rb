require 'sinatra'
require 'newrelic_rpm'

require 'padrino-helpers'
require 'log4r'
require 'compass'
require 'sprockets'
require 'sprockets-helpers'
require 'sprockets-sass'
require 'bootstrap-sass'
require 'oauth2'

# Setup logging
outputter = Log4r::StderrOutputter.new('stderr')
outputter.formatter = Log4r::PatternFormatter.new(pattern: '%d %c %m')
Log4r::Logger.new('Steno').add(outputter)
Log4r::Logger.new('Slaw').add(outputter)

$:.unshift(File.join(File.dirname(__FILE__), 'lib'))
require 'steno/document'
require 'steno/document_parser'
require 'steno/helpers'

class StenoApp < Sinatra::Base
  set :root,          File.dirname(__FILE__)
  set :sprockets,     Sprockets::Environment.new(root)
  set :precompile,    [ /\w+\.(?!js|css).+/, /app.(css|js)$/ ]
  set :assets_prefix, '/assets'
  set :digest_assets, false

  set :haml,          format: :html5
  disable :protect_from_csrf
  enable :logging

  register Padrino::Helpers

  configure do
    # Setup Sprockets
    %w{javascripts stylesheets images}.each do |type|
      sprockets.append_path File.join(root, 'assets', type)
      sprockets.append_path Compass::Frameworks['bootstrap'].templates_directory + "/../vendor/assets/#{type}"
    end
 
    # Configure Sprockets::Helpers (if necessary)
    Sprockets::Helpers.configure do |config|
      config.environment = sprockets
      config.prefix      = assets_prefix
      config.digest      = digest_assets
      config.public_path = public_folder
      config.debug       = true if development?
    end

    # find the pdftotext binary
    bin = case RUBY_PLATFORM
          when /darwin/
            "pdftotext-mac"
          else
            "pdftotext"
          end
    path = File.expand_path('bin', File.dirname(__FILE__))
    Slaw::Extract::Extractor.pdftotext_path = File.join(path, bin)
  end

  helpers do
    include Sprockets::Helpers
    include Steno::Helpers
  end

  get "/" do
    haml :index
  end

  post "/parse" do
    parser = Steno::DocumentParser.new
    parser.metadata = Steno::Metadata.new(params[:doc][:meta])
    parser.options = {
      section_number_after_title: params[:doc][:options][:section_number_after_title].present?
    }

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

    @doc = doc.xml_doc
    toc_html = haml(:toc, layout: false)

    content_type "application/json"
    {
      "html" => doc.render,
      "toc"  => toc_html,
    }.to_json
  end

  post "/sanitise" do
    doc = Steno::Document.new
    doc.xml = params[:doc][:xml]

    doc.postprocess!

    content_type "application/json"
    {
      "xml" => doc.xml
    }.to_json
  end

  post "/validate" do
    doc = Steno::Document.new
    doc.xml = params[:doc][:xml]

    doc.validate!

    content_type "application/json"
    {
      "validate_errors" => doc.validate_errors,
      "validates" => doc.validates?
    }.to_json
  end

  get "/auth/github/callback" do
    cli = OAuth2::Client.new(nil, nil, token_url: 'https://github.com/login/oauth/access_token')
    begin
      @token = cli.get_token(
        client_id: '7aeef0a6887e9e035a65',
        client_secret: ENV['GITHUB_CLIENT_SECRET'],
        state: params[:state],
        code: params[:code]).token
    rescue Exception => e
      logger.info("Couldn't get token from github: #{e}")
      @token = nil
    end

    haml :github_callback, layout: false
  end

  post '/convert-to-text' do
    content_type 'application/json'
    upload = params['file']

    # extract it
    extractor = Slaw::Extract::Extractor.new
    text = case upload[:type]
           when "text/plain"
             extractor.extract_from_text(upload[:tempfile].path)
           when "application/pdf"
             extractor.extract_from_pdf(upload[:tempfile].path)
           end

    if text.nil?
      {"error" => "I only know how to import PDF and text files."}.to_json
    else
      text = Steno::DocumentParser.new.preprocess(text)

      {
        "text" => text,
        "error" => nil,
      }.to_json
    end
  end

  get '/ping' do
    'a-ok'
  end
  newrelic_ignore '/ping'
end
