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
          if self.event_type == 'AUTHORISED' || self.event_type == 'SENT_FOR_AUTHORISATION'
            payment_method = Spree::PaymentMethod.find_by_type('Spree::Gateway::WorldpayIframe')
            payment_method.create_payment_source(order.id, xml_response)
          elsif self.event_type == 'CAPTURED'
            payment = order.payments.joins(:payment_method).where("spree_payment_methods.type =? and spree_payments.source_id is not null", 'Spree::Gateway::WorldpayIframe').first
            payment.capture! if payment.present?
          end
        end
      rescue Exception => e
        ExceptionNotifier.notify_exception(e, :env => 'production', :data => {:message => "was doing something wrong"})
      end
    end
  end
end