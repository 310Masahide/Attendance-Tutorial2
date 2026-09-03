Rails.application.routes.draw do
  root 'static_pages#top'
  get '/signup', to: 'users#new'

  # ログイン機能
  get    '/login', to: 'sessions#new'
  post   '/login', to: 'sessions#create'
  delete '/logout', to: 'sessions#destroy'

  resources :users do
    member do
      get 'edit_basic_info'
      patch 'update_basic_info'
      get 'attendances/edit_one_month'
      patch 'attendances/update_one_month'
      get   'received_overtime_requests', to: 'received_overtime_requests#index',        as: :received_overtime_requests
      patch 'received_overtime_requests', to: 'received_overtime_requests#bulk_update',  as: :bulk_update_received_overtime_requests
    end
    resources :attendances, only: :update
    resources :overtime_requests, only: [:new, :create, :edit, :update, :destroy] do
      collection { get :results }
    end
  end
end