Spree::Order.class_eval do

  # Return available payment methods
  def available_payment_methods
    @available_payment_methods ||= Spree::PaymentMethod.where(active: true, display_on: ['both', 'front_end', '']).order(:updated_at)
    country_iso = self.billing_address.country.iso3
    @available_payment_methods.select{|s| s.type != 'Spree::Gateway::WorldpayIframe' || s.eligible?(self.currency, country_iso)}
  end

  # Update payment information on order complete
  def create_payment_information
    if self.state == 'complete' && self.payment_state == 'balance_due'
      notifiy = Spree::WorldpayNotification.where(order_id: self.id, event_type: 'AUTHORISED').last
      notifiy.handle! if notifiy.present?
    end
  end

  def street_address
    billing_address.address1 + ' ' + billing_address.address2
  end
end