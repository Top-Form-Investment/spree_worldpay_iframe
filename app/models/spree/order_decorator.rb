Spree::Order.class_eval do

  after_save :create_payment_information

  # Return available payment methods
  def available_payment_methods
    @available_payment_methods ||= (Spree::PaymentMethod.available(:front_end) + Spree::PaymentMethod.available(:both)).uniq
    country_iso = self.billing_address.country.iso3
    @available_payment_methods.select{|s| s.type != 'Spree::Gateway::WorldpayIframe' || s.eligible?(self.currency, country_iso)}
  end

  # Update payment information on order complete
  def create_payment_information
    notifiy = Spree::WorldpayNotification.where(order_id: self.id, event_type: 'AUTHORISED').last
    notifiy.handle! if notifiy.present?
  end

  def street_address
    billing_address.address1 + ' ' + billing_address.address2
  end
end