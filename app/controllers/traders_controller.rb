class TradersController < ApplicationController
  # Retourne tous les traders
  def index
    auth_url = ENV['URL_AUTH']
    uri = URI("#{auth_url}/users/roles/traders")

    response = Net::HTTP.get_response(uri)

    if response.is_a?(Net::HTTPSuccess)
      traders = JSON.parse(response.body)
      render json: traders
    else
      render json: { error: "Failed to fetch traders: #{response.message}" }, status: response.code.to_i
    end
  rescue StandardError => e
    render json: { error: "An error occurred: #{e.message}" }, status: :internal_server_error
  end

  def lots
    trader = Trader.find(params[:trader_id])
    lots = trader.lots
    render json: lots.map { |lot| { id: lot.id.to_s, status: lot.status } }
  rescue Mongoid::Errors::DocumentNotFound
    render json: { error: 'Trader not found' }, status: :not_found
  end

  # Assigne un lot à un trader
  def assign_lot
    lot_id = params[:lot_id]
    assets_url = ENV['ASSETS_URL']
    if assets_url.nil?
      return render json: { error: 'Missing URL_ASSETS environment variable' },
                    status: :internal_server_error
    end

    # Vérification du lot via l'API externe
    uri = URI("#{assets_url}/lots/#{lot_id}")
    response = Net::HTTP.get_response(uri)
    unless response.is_a?(Net::HTTPSuccess)
      return render json: { error: "Failed to fetch lot: #{response.message}" }, status: response.code.to_i
    end

    lot_data = JSON.parse(response.body)
    if lot_data['status'] != 'available'
      return render json: { error: 'Lot is already assigned or not available' }, status: :unprocessable_entity
    end

    # Récupération des traders via l'API Auth
    auth_url = ENV['AUTH_URL']
    uri = URI("#{auth_url}/users/roles/traders")
    response = Net::HTTP.get_response(uri)
    unless response.is_a?(Net::HTTPSuccess)
      return render json: { error: "Failed to fetch traders: #{response.message}" }, status: response.code.to_i
    end

    traders = JSON.parse(response.body)

    # Calcul des associations pour chaque trader
    trader_associations = traders.map do |trader|
      trader_id = trader['user_id']
      lots_count = Mongoid.default_client[:trader_lots].count_documents(trader_id: trader_id)
      tractors_count = Mongoid.default_client[:trader_tractors].count_documents(trader_id: trader_id)
      { id: trader_id, username: trader['username'], total: lots_count + tractors_count }
    end

    selected_trader = trader_associations.min_by { |trader| trader[:total] }
    if selected_trader.nil?
      return render json: { error: 'No trader available for assignment' }, status: :unprocessable_entity
    end

    # Insertion directe dans MongoDB
    Mongoid.default_client[:trader_lots].insert_one({ lot_id: lot_id, trader_id: selected_trader[:id] })

    render json: { message: 'Lot assigned to trader', trader_id: selected_trader[:id] }, status: :created
  rescue StandardError => e
    render json: { error: "An error occurred: #{e.message}" }, status: :internal_server_error
  end

  # Assigne un tracteur à un trader
  def assign_tractor
    tractor = Tractor.find(params[:tractor_id])
    trader = Trader.find(params[:trader_id])
    tractor.trader = trader
    if tractor.save
      render json: { message: 'Tractor assigned to trader' }, status: :created
    else
      render json: { error: 'Failed to assign tractor' }, status: :unprocessable_entity
    end
  rescue Mongoid::Errors::DocumentNotFound
    render json: { error: 'Tractor or Trader not found' }, status: :not_found
  end
end
