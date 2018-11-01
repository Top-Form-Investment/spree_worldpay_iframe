class OrderUpdateWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'worldpay_order_update'
  
  def perform(order_id)
    order = Spree::Order.find order_id
    order.create_payment_information
    order.updater.update_payment_state
    order.updater.update_shipment_state
    order.save
  end
end