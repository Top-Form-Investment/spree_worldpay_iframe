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
          if self.event_type == 'AUTHORISED'
            payment_method = Spree::PaymentMethod.find_by_type('Spree::Gateway::WorldpayIframe')
            payment_method.create_payment_source(order.id, self.event_type, xml_response)
            payment = Spree::Payment.where(order: order.id).joins(:payment_method).where("spree_payment_methods.type =? and spree_payments.source_id is not null", 'Spree::Gateway::WorldpayIframe').last
            payment.capture! if payment.present?
          elsif self.event_type == 'CAPTURED'
            payment = order.payments.joins(:payment_method).where("spree_payment_methods.type =? and spree_payments.source_id is not null", 'Spree::Gateway::WorldpayIframe').last
            if payment.blank?
              notify = Spree::WorldpayNotification.where(order_id: order.id, event_type: ['AUTHORISED','SENT_FOR_AUTHORISATION']).first
              if notify.present?
                notify.handle!
                payment = order.payments.joins(:payment_method).where("spree_payment_methods.type =? and spree_payments.source_id is not null", 'Spree::Gateway::WorldpayIframe').last
              end
            end
            payment.capture! if payment.present? && payment.state != 'completed'
          end
        end
      rescue Exception => e
        ExceptionNotifier.notify_exception(e, :env => 'production', :data => {:message => "was doing something wrong"})
      end
    end
  end
end