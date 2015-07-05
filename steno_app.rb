require 'sinatra'
require 'sinatra/cross_origin'
require 'newrelic_rpm'

require 'padrino-helpers'
require 'log4r'
require 'compass'
require 'sprockets'
require 'sprockets-helpers'
require 'sprockets-sass'
require 'bootstrap-sass'
require 'oauth2'

require 'slaw'
require 'slaw/za/bylaw_generator'

# Setup logging
outputter = Log4r::StderrOutputter.new('stderr')
outputter.formatter = Log4r::PatternFormatter.new(pattern: '%d %c %m')
Log4r::Logger.new('Steno').add(outputter)
Log4r::Logger.new('Slaw').add(outputter)

$:.unshift(File.join(File.dirname(__FILE__), 'lib'))
require 'steno/region'
require 'steno/helpers'
require 'steno/search'

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
  register Sinatra::CrossOrigin

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
    content_type "application/json"

    generator = Slaw::ZA::BylawGenerator.new
    generator.parser.options = {
      section_number_after_title: params[:doc][:options][:section_number_after_title].present?
    }

    begin
      errors = []
      bylaw = generator.generate_from_text(params[:doc][:source_text])

      meta = params[:doc][:meta]

      bylaw.title = meta[:title]
      bylaw.date = meta[:pub_date]
      bylaw.year = meta[:pub_date].split('-')[0]
      bylaw.name = meta[:short_name]
      bylaw.region = meta[:region]

      bylaw.published!(
        name: meta[:pub_name],
        date: meta[:pub_date],
        number: meta[:pub_number],
      )

      # set council manually
      council = bylaw.doc.at_css('#council')
      council['href'] = "/ontology/organization/za/council.#{meta[:region]}"
      if region = Steno::Region.for_code(meta[:region])
        council['showAs'] = region.council
      end
    rescue Slaw::Parse::ParseError => e
      errors << e
    end

    {
      "parse_errors" => errors,
      "xml" => bylaw && bylaw.to_xml(indent: 2)
    }.to_json
  end

  post "/render" do
    bylaw = Slaw::ByLaw.new
    bylaw.parse(params[:doc][:xml])

    renderer = Slaw::Render::HTMLRenderer.new
    html = renderer.render(bylaw.doc, '/root/')
    if @schedules = bylaw.schedules
      html += " " + renderer.render_node(@schedules, '/root/')
    end

    @doc = bylaw.doc
    toc_html = haml(:toc, layout: false)

    content_type "application/json"
    {
      "html" => html,
      "toc"  => toc_html,
    }.to_json
  end

  post "/cleanup" do
    text = params[:text]

    cleanser = Slaw::Parse::Cleanser.new
    text = cleanser.cleanup(text)
    text = cleanser.reformat(text)

    content_type "application/json"
    {
      "text" => text,
    }.to_json
  end

  post "/sanitise" do
    bylaw = Slaw::ByLaw.new
    bylaw.parse(params[:doc][:xml])

    generator = Slaw::ZA::BylawGenerator.new
    generator.builder.postprocess(bylaw.doc)

    content_type "application/json"
    {
      "xml" => bylaw.to_xml(indent: 2)
    }.to_json
  end

  post "/validate" do
    bylaw = Slaw::ByLaw.new
    bylaw.parse(params[:doc][:xml])

    errors = bylaw.validate.map do |e|
      {
        message: e.to_s,
        line: e.line,
        column: e.column,
      }
    end

    content_type "application/json"
    {
      "validate_errors" => errors,
      "validates" => errors.empty?
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

  post '/extract' do
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
      {
        "text" => text,
        "error" => nil,
      }.to_json
    end
  end

  # search
  get '/search' do
    cross_origin
    content_type 'application/json'

    if not params[:q]
      return {
        hits: {
          total: 0,
        },
        took: 0,
      }.to_json
    end

    results = Steno::Search.searcher.search(params[:q], 0, 10, params[:region_name])

    return results.to_json
  end

  get '/ping' do
    'a-ok'
  end
  newrelic_ignore '/ping'
end
