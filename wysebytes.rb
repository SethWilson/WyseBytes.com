require 'rubygems'
require 'sinatra'
require 'erb'
require 'lib/gs'
require 'lib/wiki_data'
require 'oauth'
require 'haml'


configure do
  set :sessions, true
  @@config = YAML.load_file("config.yml") rescue nil || {}
end

before do
  next if request.path_info =~ /ping$/
  @user = session[:user]
  
  @con = OAuth::Consumer.new(ENV['CONSUMER_KEY'] || @@config['consumer_key'], ENV['CONSUMER_SECRET'] || @@config['consumer_secret'],
                                {:site => 'https://www.google.com',
                                 :request_token_path => '/accounts/OAuthGetRequestToken',
                                 :access_token_path => '/accounts/OAuthGetAccessToken',
                                 :authorize_path => '/accounts/OAuthAuthorizeToken'})
  
  
end


# store the request tokens and send to Google
get '/connect' do
  rt = @con.get_request_token({}, {:scope => ENV['SCOPE'] || @@config['SCOPE']})
  
  request_token = @client.request_token(
    :oauth_callback => ENV['CALLBACK_URL'] || @@config['callback_url']
  )
  session[:request_token] = rt.token
  session[:request_token_secret] = rt.secret
  redirect rt.authorize_url
end

# auth URL is called by google after the user has accepted the application
# this is configured on the Google manage my domain page
get '/auth' do
  # Exchange the request token for an access token.
  
  begin
    @access_token = @client.authorize(
      session[:request_token],
      session[:request_token_secret],
      :oauth_verifier => params[:oauth_verifier]
    )
  rescue OAuth::Unauthorized
  end
  
  if @client.authorized?
      # Storing the access tokens so we don't have to go back to Twitter again
      # in this session.  In a larger app you would probably persist these details somewhere.
      session[:access_token] = @access_token.token
      session[:secret_token] = @access_token.secret
      session[:user] = true
      redirect '/timeline'
    else
      redirect '/'
  end
end


get '/' do
  if request.xhr?
    "Hello, AJAX!"
  else 
   erb :index
 end
end



post '/sendjson' do

  request.body.read

end

get '/:name' do
    redirect '/', 307
end

post '/search/' do
  "Got your post'd data #{params["search"]}"
  
  @email = "sethdubya@gmail.com"
  @password = "1234Idtw4r!"
  gs = SpreadsheetExamples.new()

  gs.authenticate(@email, @password)

  search_terms = [params["search"]]
  
  wiki_data = WikiData.new("Daily%20Wiki", search_terms, @email, @password)
  
  @wiki_entries = wiki_data.get_wiki_data()
  
  haml :search
  
end


get '/disconnect' do
  session[:user] = nil
  session[:request_token] = nil
  session[:request_token_secret] = nil
  session[:access_token] = nil
  session[:secret_token] = nil
  redirect '/'
end
