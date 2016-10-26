require 'sinatra'
require 'sinatra/reloader'
require 'tilt/erubis'

set :server, 'webrick'

configure do
  enable :sessions
  set    :session_secret, 'secret'
end

before do
  session[:lists] ||= []
end

get '/' do
  redirect '/lists'
end

# Index
get '/lists' do
  @lists = session[:lists]

  erb :lists
end

def error_for_list_name(name)
  if !(1..100).cover? name.size
    'Name must be 1 to 100 chars long'
  elsif session[:lists].any? { |list| list[:name] == name }
    'Name already taken'
  end
end

# New
get '/lists/new' do
  erb :lists_new
end

# Create
post '/lists' do
  name = params[:list_name].strip

  error = error_for_list_name(name)
  if error
    session[:error] = error

    redirect '/lists/new'
  else
    session[:lists] << { name: name, todos: [] }
    session[:success] = 'New List Created'

    redirect '/lists'
  end
end

# Delete
post '/lists/:name' do
  name = params[:name]
  session[:lists].reject! { |list| list[:name] == name }

  redirect '/lists'
end
