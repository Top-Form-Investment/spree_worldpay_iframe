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

  def worldpay_captured?
    Spree::WorldpayNotification.where(order_id: self.order_id, event_type: 'CAPTURED').present?
  end

  def actions
    return [] unless payment_source and payment_source.respond_to? :actions
    if(self.payment_method.present? && self.payment_method.type == 'Spree::Gateway::WorldpayIframe')
      payment_source.actions.select { |action| (!payment_source.respond_to?("can_#{action}?") or payment_source.send("can_#{action}?", self)) && (action != 'credit' || self.worldpay_captured?)}
    else
      payment_source.actions.select { |action| !payment_source.respond_to?("can_#{action}?") or payment_source.send("can_#{action}?", self) }
    end
  end

end