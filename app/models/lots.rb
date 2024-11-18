class Lot
  include Mongoid::Document

  field :trader_id, type: String
  field :status, type: String
  field :volume, type: Integer
  field :type, type: String
  field :max_price, type: Integer
  field :start_checkpoint_id, type: String
  field :end_checkpoint_id, type: String
end
