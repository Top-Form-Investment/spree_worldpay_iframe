Spree::Order.class_eval do

  # Return available payment methods
  def available_payment_methods
    @available_payment_methods ||= Spree::PaymentMethod.available_on_front_end.order(:position)
    country_iso = self.billing_address.country.iso3
    @available_payment_methods.select{|s| s.type != 'Spree::Gateway::WorldpayIframe' || s.eligible?(self.currency, country_iso)}
  end

  # Update payment information on order complete
  def create_payment_information
    notifiy = Spree::WorldpayNotification.where(order_id: self.id).last
    notifiy.handle! if notifiy.present?
  end

end