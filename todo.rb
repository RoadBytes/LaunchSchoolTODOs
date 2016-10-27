require 'sinatra'
require 'sinatra/reloader'
require 'sinatra/content_for'
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

def error_for_edit_list_name(old_name, new_name)
  # take out list with name first
  other_lists = session[:lists].select { |list| list[:name] != old_name }
  if !(1..100).cover? new_name.size
    'Name must be 1 to 100 chars long'
  elsif other_lists.any? { |list| list[:name] == new_name }
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

# List Delete
post '/lists/:id/delete' do
  id = params[:id].to_i
  session[:lists].delete_at(id)
  session[:success] = 'List Deleted'

  redirect '/lists'
end

# List Show
get '/lists/:id' do
  @id = params[:id].to_i
  @list = session[:lists][@id]

  erb :list
end

# List Edit
get '/lists/:id/edit' do
  @id   = params[:id].to_i
  @list = session[:lists][@id]

  erb :list_edit
end

# List Update
post '/lists/:id' do
  @id   = params[:id].to_i
  @list = session[:lists][@id]

  @old_name = @list[:name]
  @new_name = params[:list_name].strip

  error = error_for_edit_list_name(@old_name, @new_name)
  if error
    session[:error] = error

    erb :list_edit
  else
    @list[:name] = @new_name
    session[:success] = 'List Updated'

    redirect "/lists/#{@id}"
  end
end

# Todo Create
post '/lists/:id/todo' do
  @name = params[:name]
  @todo = params[:todo]
  @list = session[:lists].find { |list| list[:name] == @name }
  @list[:todos] << @todo

  erb :list
end
