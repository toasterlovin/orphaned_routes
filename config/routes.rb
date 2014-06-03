Rails.application.routes.draw do
  resources :things

  # No controller exists
  # resources :doodads

  # Action magically created because view exists
  # resources :widgets
end
