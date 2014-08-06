PaperclipDemo::Application.routes.draw do
  resources :friends
  root :to => 'friends#index'

  get '/ping', to: 'application#ping'
end
