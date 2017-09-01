Spree::Payment.class_eval do

  after_save :check_notification


  ## Background guide assignment
  def check_notification
    notifications = Spree::WorldpayNotification.where(order_id: self.order_id)
    if self.state == 'checkout' && self.order.state == 'completed'
      notify = notifications.select{|s| ['AUTHORISED','SENT_FOR_AUTHORISATION'].include?(s.event_type)}.first
      if notify.present?
        notify.handle!
      end
    end
  end
end