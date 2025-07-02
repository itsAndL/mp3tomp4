# config/routes.rb
Rails.application.routes.draw do
  # Devise routes must come first
  devise_for :users, controllers: {
    omniauth_callbacks: "users/omniauth_callbacks"
  }

  root "home#index"

  resources :videos, only: [ :index, :show, :new, :create, :update ] do
    member do
      patch :set_privacy
      post :set_thumbnail
    end
  end

  resources :playlists do
    member do
      post :add_video
      delete :remove_video
      patch :reorder_video
    end
  end

  resources :video_conversions, only: [ :index, :new, :create, :show ] do
    member do
      get :status
    end
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
