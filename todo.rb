require "sinatra"
require "sinatra/reloader" if development?
require "sinatra/content_for"
require "tilt/erubis"

configure do
  enable :sessions
  set :session_secret, 'secret'
end

helpers do
  def list_complete?(list)
    todos_count(list) > 0 && todos_remaining_count(list) == 0
  end

  def list_class(list)
    "complete" if list_complete?(list)
  end

  def todos_count(list)
    list[:todos].size
  end

  def todos_remaining_count(list)
    list[:todos].count { |todo| todo[:completed] == false }
  end

  def sort_lists(lists)
    lists.sort_by { |list| list_complete?(list) ? 1 : 0 }
         .each { |list| yield list, lists.index(list) }
  end

  def sort_todos(todos)
    todos.sort_by { |todo| todo[:completed] ? 1 : 0 }
         .each { |todo| yield todo, todos.index(todo) }
  end
end

before do
  session[:lists] ||= []
end

get "/" do
  redirect "/lists"
end

# View list of all lists
get "/lists" do
  @lists = session[:lists]
  erb :lists, layout: :layout
end

# Render the new list form
get "/lists/new" do
  erb :new_list, layout: :layout
end

# Return an error message if the name is invalid. Return nil if name is valid.
def error_for_list_name(name)
  if !(1..100).cover? name.size
    "List name must be between 1 and 100 characters."
  elsif session[:lists].any? { |list| list[:name] == name }
    "List name must be unique."
  end
end

# Return an error message if the todo is invalid. Return nil if name is valid.
def error_for_todo(name)
  if !(1..100).cover? name.size
    "Todo must be between 1 and 100 characters."
  end
end

# Create a new list
post "/lists" do
  list_name = params[:list_name].strip

  error = error_for_list_name(list_name)
  if error
    session[:error] = error
    erb :new_list, layout: :layout
  else
    session[:lists] << { name: list_name, todos: [] }
    session[:success] = "The list has been created."
    redirect "/lists"
  end
end

# View a single todo list
get "/lists/:list_id" do
  @list_id = params[:list_id].to_i
  @list = session[:lists][@list_id]

  erb :list, layout: :layout
end

get "/lists/:list_id/edit" do
  @list_id = params[:list_id].to_i
  @list = session[:lists][@list_id]

  erb :edit_list, layout: :layout
end

# Update an existing todo list
post "/lists/:list_id" do
  @list_id = params[:list_id].to_i
  list_name = params[:list_name].strip

  error = error_for_list_name(list_name)
  if error
    session[:error] = error
    erb :edit_list, layout: :layout
  else
    session[:lists][@list_id][:name] = list_name
    session[:success] = "The list has been edited."
    redirect "/lists/#{@list_id}"
  end
end

# Delete a todo list
post "/lists/:list_id/delete" do
  list_id = params[:list_id].to_i
  session[:lists].delete_at(list_id)
  session[:success] = "The list has been deleted."

  redirect "/lists"
end

# Add a new todo to a list
post "/lists/:list_id/todos" do
  @list_id = params[:list_id].to_i
  @list = session[:lists][@list_id]
  text = params[:todo].strip

  error = error_for_todo(text)
  if error
    session[:error] = error
    erb :list, layout: :layout
  else
    @list[:todos] << { name: text, completed: false }
    session[:success] = "The todo was added."
    redirect "/lists/#{@list_id}"
  end
end

# Delete a single todo
post "/lists/:list_id/todos/:id/delete" do
  @list_id = params[:list_id].to_i
  @list = session[:lists][@list_id]

  todo_id = params[:id].to_i

  @list[:todos].delete_at(todo_id)
  session[:success] = "The todo has been deleted."
  redirect "/lists/#{@list_id}"
end

# Update status of a todo
post "/lists/:list_id/todos/:id" do
  @list_id  = params[:list_id].to_i
  @list = session[:lists][@list_id]

  todo_id = params[:id].to_i
  is_completed = params[:completed] == 'true'
  @list[:todos][todo_id][:completed] = is_completed
  session[:success] = "The todo has been updated."
  redirect "/lists/#{@list_id}"
end

# Mark all todos on a list as complete
post "/lists/:list_id/complete_all" do
  @list_id  = params[:list_id].to_i
  @list = session[:lists][@list_id]

  @list[:todos].each do |todo|
    todo[:completed] = true
  end

  session[:success] = "All todos have been completed."
  redirect "/lists/#{@list_id}"
end


