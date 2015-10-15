Rails.application.routes.draw do
  get 'benchmarks/simple'

  resources :benchmarks, only: :none do
    collection do
      get :simple
    end
  end
end