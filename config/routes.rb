Rails.application.routes.draw do
  root 'static_pages#top'
  get '/signup', to: 'users#new'

  # ログイン機能
  get    '/login', to: 'sessions#new'
  post   '/login', to: 'sessions#create'
  delete '/logout', to: 'sessions#destroy'

  resources :users do
    collection do
      post 'import'
    end
    member do
      get 'edit_basic_info'
      patch 'update_basic_info'
      get 'attendances/edit_one_month'
      patch 'attendances/update_one_month'
      get 'attendances/correction_logs'
      get   'received_overtime_requests', to: 'received_overtime_requests#index',        as: :received_overtime_requests
      patch 'received_overtime_requests', to: 'received_overtime_requests#bulk_update',  as: :bulk_update_received_overtime_requests
      get   'received_attendance_correction_requests', to: 'received_attendance_correction_requests#index',
            as: :received_attendance_correction_requests
      patch 'received_attendance_correction_requests', to: 'received_attendance_correction_requests#bulk_update',
            as: :bulk_update_received_attendance_correction_requests
      get   'received_monthly_approvals', to: 'received_monthly_approvals#index',        as: :received_monthly_approvals
      patch 'received_monthly_approvals', to: 'received_monthly_approvals#bulk_update',  as: :bulk_update_received_monthly_approvals
    end
    resources :overtime_requests, only: [:new, :create, :edit, :update, :destroy]
    resources :monthly_approvals, only: [:create, :update]
  end
end