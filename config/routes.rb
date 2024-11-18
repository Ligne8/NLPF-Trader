Rails.application.routes.draw do
  post '/traders/lots/:lot_id', to: 'traders#assign_lot'
  get '/traders/lots/:trader_id', to: 'traders#get_trader_lots'
  post '/traders/tractors/:tractor_id', to: 'traders#assign_tractor'
  get '/traders/tractors/:trader_id', to: 'traders#get_trader_tractors'
end
