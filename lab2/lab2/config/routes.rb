Rails.application.routes.draw do
  get 'response/simple'
  root 'response#simple'
  resources :response, only: :none do
    collection do
      get :simple
    end
  end
end