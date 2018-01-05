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
    if self.state == 'complete' && self.state_was != 'complete'
      notifiy = Spree::WorldpayNotification.where(order_id: self.id).first
      notifiy.handle! if notifiy.present?
    end
  end

end