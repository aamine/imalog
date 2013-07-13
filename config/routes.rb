Imalog::Application.routes.draw do
  root to: 'articles#index'
  resources :articles
  resources :sessions, only: %i(new create destroy)
end
