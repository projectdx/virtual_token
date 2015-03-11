Rails.application.routes.draw do
  devise_for :users
  resources :tokens do
    resources :token_requests, :as => :requests do
      member do
        put 'move'
      end
    end
  end
  root :to => 'tokens#index'
end
