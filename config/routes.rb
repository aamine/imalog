Imalog::Application.routes.draw do
  root to: 'articles#index', as: :blog
  resources :articles
  resources :sessions, only: %i(new create destroy)
end
