Rails.application.routes.draw do
  post '/traders/lots/:lot_id', to: 'traders#assign_lot'
  get '/traders/lots/:trader_id', to: 'traders#get_trader_lots'
end
