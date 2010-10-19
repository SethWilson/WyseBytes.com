require 'rubygems'
require 'sinatra'
require 'lib/gs'
require 'lib/wiki_data'
require 'oauth'
require 'haml'


enable :sessions

configure do
  set :sessions, true
  @@config = YAML.load_file("config.yml") rescue nil || {}
end

before do
  session[:oauth] ||= {}  
  
  @consumer = OAuth::Consumer.new(ENV['CONSUMER_KEY'] || @@config['consumer_key'], ENV['CONSUMER_SECRET'] || @@config['consumer_secret'],
                                {:site => 'https://www.google.com',
                                 :request_token_path => '/accounts/OAuthGetRequestToken',
                                 :access_token_path => '/accounts/OAuthGetAccessToken',
                                 :authorize_path => '/accounts/OAuthAuthorizeToken'})
  
  if !session[:oauth][:request_token].nil? && !session[:oauth][:request_token_secret].nil?
    @request_token = OAuth::RequestToken.new(@consumer, session[:oauth][:request_token], session[:oauth][:request_token_secret])
  end
  
  if !session[:oauth][:access_token].nil? && !session[:oauth][:access_token_secret].nil?
    @access_token = OAuth::AccessToken.new(@consumer, session[:oauth][:access_token], session[:oauth][:access_token_secret])
  end
  
  
end

get "/" do
  if @access_token
    
    haml :index
  else
    '<a href="/request">Sign On</a>'
  end
end

get "/request" do
  @request_token = @consumer.get_request_token({}, :oauth_callback => "http://#{request.host}/auth", :scope => 'https://spreadsheets.google.com/feeds/')
  session[:oauth][:request_token] = @request_token.token
  session[:oauth][:request_token_secret] = @request_token.secret
  redirect @request_token.authorize_url
end

get "/auth" do
  @access_token = @request_token.get_access_token :oauth_verifier => params[:oauth_verifier]
  session[:oauth][:access_token] = @access_token.token
  session[:oauth][:access_token_secret] = @access_token.secret
  redirect "/"
end

get "/logout" do
  session[:oauth] = {}
  redirect "/"
end