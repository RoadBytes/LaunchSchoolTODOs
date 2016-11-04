require 'sinatra'
require 'sinatra/reloader' if development?
require 'sinatra/content_for'
require 'tilt/erubis'

set :server, 'webrick'

configure do
  enable :sessions
  set    :session_secret, 'secret'
end

helpers do
  def todos_count(list)
    list[:todos].size
  end

  def list_completed?(list)
    todos_not_completed_size(list) == 0 && todos_count(list) > 0
  end

  def todos_not_completed_size(list)
    list[:todos].select { |todo| todo[:completed] == false }.size
  end

  def sorted_lists(lists)
    complete, incomplete = lists.partition { |list| list_completed? list }

    incomplete.each { |list| yield(lists.index(list), list) }
    complete.each { |list| yield(lists.index(list), list) }
  end

  def sorted_todos(list)
    todos = list[:todos]
    complete, incomplete = todos.partition { |todo| todo[:completed] }

    incomplete.each { |todo| yield(todo) }
    complete.each { |todo| yield(todo) }
  end
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

def error_for_todo_name(name)
  'TODO must be 1 to 100 chars long' unless (1..100).cover? name.size
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

def load_list(index)
  list = session[:lists][index]
  return list if list

  session[:error] = 'Sorry List does not exist'
  redirect :lists
end

# New
get '/lists/new' do
  erb :lists_new
end

# List Create
post '/lists' do
  name  = params[:list_name].strip

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

# List Destroy
post '/lists/:id/delete' do
  id = params[:id].to_i
  session[:lists].delete_at(id)

  if env["HTTP_X_REQUESTED_WITH"] == "XMLHttpRequest"
    "/lists"
  else
    session[:success] = 'List Deleted'
    redirect '/lists'
  end
end

# List Show
get '/lists/:id' do
  @list_id = params[:id].to_i
  @list    = load_list(@list_id)

  erb :list
end

# List Edit
get '/lists/:id/edit' do
  @id   = params[:id].to_i
  @list = load_list(@id)

  erb :list_edit
end

# List Update
post '/lists/:id' do
  @id       = params[:id].to_i
  @list     = load_list(@id)
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

def next_id(todos)
  max_id = todos.map{ |todo| todo[:id] }.max.to_i
  max_id + 1
end

# Todo Create
post '/lists/:list_id/todos' do
  @list_id = params[:list_id].to_i
  todo     = params[:todo].strip
  @list    = load_list(@list_id)

  error = error_for_todo_name(todo)
  if error
    session[:error] = error

    erb :list
  else
    todos = @list[:todos] 
    todos << { id: next_id(todos), name: todo, completed: false }
    session[:success] = 'TODO Added'

    redirect "lists/#{@list_id}"
  end
end

# Todo Completed
post '/lists/:list_id/todos/:todo_id/completed' do
  @list_id = params[:list_id].to_i
  @list    = load_list(@list_id)
  todo_id  = params[:todo_id].to_i
  todo     = @list[:todos].find { |todo_item| todo_item[:id] == todo_id }
  value    = (params[:completed] == 'true')

  todo[:completed]  = value
  session[:success] = "Todo: #{todo[:name]} updated"

  redirect "lists/#{@list_id}"
end

# Todo Destroy
post '/lists/:list_id/todos/:todo_id/delete' do
  @list_id = params[:list_id].to_i
  @list    = load_list(@list_id)
  todo_id  = params[:todo_id].to_i

  @list[:todos].reject! { |todo| todo[:id] == todo_id }

  if env["HTTP_X_REQUESTED_WITH"] == "XMLHttpRequest"
    status 204
  else
    session[:success] = 'TODO Deleted'
    redirect "/lists/#{@list_id}"
  end
end

# Todo All Completed
post '/lists/:list_id/complete_all' do
  @list_id = params[:list_id].to_i
  @list    = load_list(@list_id)

  @list[:todos].each { |todo| todo[:completed] = true }
  session[:success] = 'All Todos completed'

  redirect "/lists/#{@list_id}"
end
