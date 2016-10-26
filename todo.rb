require "sinatra"
require "sinatra/reloader"
require "tilt/erubis"

set :server, 'webrick'

get "/" do
  erb "You have no lists.", layout: :layout
end
