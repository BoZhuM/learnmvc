$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "config"))

require 'application'
app = Simpleapp::Application.new

app.routes do
    match '/posts/:id' => "posts#show"
    match '/posts' => "posts#index"
    match '/posts/fuck' => "posts#xxx"
    get '/friends' => "friends#index"
    resources :products
    root 'welcome#index'
end

run app
