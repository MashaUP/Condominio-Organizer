Rails.application.routes.draw do
  get 'admin/index'
  post 'condominos/eleva_condomino', to: 'condominos#eleva_condomino'
  post 'admin/eleva_ad_admin', to: 'admin#eleva_ad_admin'
  delete "/admin/:id" => "admin#destroy", as: :user
  resources :comments
  resources :requests
  devise_for :users, controllers: { omniauth_callbacks: 'users/omniauth_callbacks' }
  authenticate(:users) do
  	resources :users
  end
  resources :enter
  resources :post
  resources :condominos
  resources :condominios do
    resources :posts
    resources :condominos
  end
  resources :contacts, only: [:new, :create]
  root 'welcome#index'
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
