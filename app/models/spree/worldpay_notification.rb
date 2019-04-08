module Spree
  class WorldpayNotification < ActiveRecord::Base

    def self.log(response)
      doc = Nokogiri::XML(response.read)
      obj = self.new
      obj.response = doc.to_s
      obj.save
      puts "***************Worldpay Notify*************"
      puts doc.to_s
      puts "********************************************"
      obj
    end

    def handle!
      begin
        xml_response = Nokogiri::XML(self.response)
        order_code = xml_response.at_xpath('//orderStatusEvent')['orderCode']
        order_number = order_code.split('-').first
        order = Spree::Order.find_by_number order_number
        if order.present?
          self.event_type = xml_response.at_xpath('//lastEvent').content
          self.order_id = order.id
          if self.event_type == 'AUTHORISED'
            self.event_type = xml_response.at_xpath('//journal')['journalType']
          end
          self.save
          self.reload
          if self.event_type == 'AUTHORISED' || self.event_type == 'SENT_FOR_AUTHORISATION'
            payment_method = Spree::PaymentMethod.find_by_type('Spree::Gateway::WorldpayIframe')
            payment = payment_method.create_payment_source(order, self.event_type, xml_response)
            bill_address = order.bill_address
            ship_address = order.ship_address
            if payment.present? && self.event_type == 'AUTHORISED' && (ship_address.state_id == bill_address.state_id && ship_address.city.strip.downcase == bill_address.city.strip.downcase) && order.quantity <= 3
              payment.capture!
            end
          elsif self.event_type == 'CAPTURED'
            payment = Spree::Payment.where(response_code: order_code).last
            if payment.present?
              if payment.source_id.blank?
                notify = Spree::WorldpayNotification.where(order_id: order.id, event_type: ['AUTHORISED','SENT_FOR_AUTHORISATION']).last
                if notify.present?
                  notify.handle!
                  payment.reload
                end
              end
              payment.capture! if payment.state != 'completed'
              payment.update(worldpay_capture: true)
            end
          end
        end
      rescue Exception => e
        ExceptionNotifier.notify_exception(e, :env => 'production', :data => {:message => "was doing something wrong"})
      end
    end
  end
end