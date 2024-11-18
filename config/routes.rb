Rails.application.routes.draw do
  resources :traders, only: [] do
    post 'lots/:lot_id', to: 'traders#assign_lot', on: :collection
  end
end
