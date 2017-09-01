Spree::Payment.class_eval do

  after_save :check_notification

  ## Check payment state
  def check_notification
    if self.state == 'checkout' && self.order.state == 'completed' && self.payment_method.present? && self.payment_method.type == 'Spree::Gateway::WorldpayIframe'
      puts '-----Payment----'
      notify = Spree::WorldpayNotification.where(order_id: self.order_id, event_type: ['AUTHORISED','SENT_FOR_AUTHORISATION']).first
      if notify.present?
        notify.handle!
      end
    end
  end
end