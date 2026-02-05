Rails.application.routes.draw do
  # API v0 routes
  draw :api_v0

  get "up" => "rails/health#show", as: :rails_health_check

  root "welcome#index"
end
