module Spree
  class Gateway
    class WorldpayIframe
      module PaymentRequest
        extend ActiveSupport::Concern
        TEST_URL = 'https://secure-test.worldpay.com/jsp/merchant/xml/paymentService.jsp'
        LIVE_URL = 'https://secure.worldpay.com/jsp/merchant/xml/paymentService.jsp'
        CARD_CODES = {
          'VISA-SSL'       => 'visa',
          'ECMC-SSL'       => 'master',
          'DISCOVER-SSL'   => 'discover',
          'AMEX-SSL'       => 'american_express',
          'JCB-SSL'        => 'jcb',
          'MAESTRO-SSL'    => 'maestro',
          'LASER-SSL'      => 'laser',
          'DINERS-SSL'     => 'diners_club',
          'MAESTRO-SSL'    => 'switch'
        }
        def api_url
          self.preferences[:test_mode].present? ? TEST_URL : LIVE_URL
        end

        def setup_api_call
          url = URI(api_url)
          http = Net::HTTP.new(url.host, url.port)
          http.use_ssl = true
          http.verify_mode = OpenSSL::SSL::VERIFY_NONE
          request = Net::HTTP::Post.new(url)
          request["content-type"] = 'text/xml'
          request["cache-control"] = 'no-cache'
          request.basic_auth(self.preferences[:login], self.preferences[:password])
          [http, request]
        end

        def build_request
          xml = Builder::XmlMarkup.new :indent => 2
          xml.instruct! :xml, :encoding => 'UTF-8'
          xml.declare! :DOCTYPE, :paymentService, :PUBLIC, "-//WorldPay//DTD WorldPay PaymentService v1//EN", "http://dtd.worldpay.com/paymentService_v1.dtd"
          xml.tag! 'paymentService', 'version' => "1.4", 'merchantCode' => self.preferences[:merchant_code] do
            yield xml
          end
          xml.target!
        end


        def hpp_payment_url(order_id)
          http, request = setup_api_call
          order = Spree::Order.find_by_id(order_id)
          billing_address = order.billing_address
          order_code = "#{order.number}-#{Time.now.to_i}"
          builder = build_request do |xml|
            xml.submit do
              xml.order(orderCode: "#{order.number}-#{Time.now.to_i}", installationId: self.preferences[:installation_id]) do
                xml.description order.line_items.map(&:sku).join(',')
                xml.amount(exponent: '2', currencyCode: order.currency, value: order.total.to_money.cents)
                xml.orderContent order.line_items.map(&:sku).join(',')
                xml.paymentMethodMask do
                  xml.include(code: 'ALL')
                end
                xml.shopper do
                  xml.shopperEmailAddress 'admin@sandandsky.com'
                end
                xml.billingAddress do
                  xml.address do
                    xml.address1 billing_address.address1
                    xml.postalCode billing_address.zipcode
                    xml.city billing_address.city
                    xml.countryCode billing_address.country.iso
                  end
                end
              end
            end
          end
          request.body = builder
          response = http.request(request)
          response = Nokogiri::XML(response.read_body)
          [order_code, response.at_xpath('//error').try(:content), response.at_xpath('//reference').try(:content)]
        end

        def order_inquiry(order_code)
          http, request = setup_api_call
          builder = build_request do |xml|
            xml.tag! 'inquiry' do
              xml.tag! 'orderInquiry', 'orderCode' => order_code
            end
          end
          request.body = builder
          response = http.request(request)
          response = Nokogiri::XML(response.read_body)
          response
        end

        def void_refund(authorization)
          void_result = false
          begin
            http, request = setup_api_call
            payment = Spree::Payment.find_by_response_code authorization
            if payment.present?
              builder = build_request do |xml|
                xml.modify do
                  xml.orderModification(orderCode: payment.response_code) do
                    xml.cancelOrRefund
                  end
                end
              end
              request.body = builder
              response = http.request(request)
              response = Nokogiri::XML(response.read_body)
              if response.at_xpath('//ok').present? && response.at_xpath('//voidReceived').present? && response.at_xpath('//voidReceived')['orderCode'] == authorization
                void_result = true
              end
            end
          rescue StandardError => e
            false
          end
          void_result
        end

        def create_payment_source(order_id, xml_response = nil)
          order = Spree::Order.find order_id
          payment = order.payments.joins(:payment_method).where("spree_payment_methods.type =? and spree_payments.source_id is null", 'Spree::Gateway::WorldpayIframe').first
          if payment.present?
            if xml_response.blank?
              xml_response = self.order_inquiry(payment.response_code)
            end
            c_month = xml_response.at_xpath('//date')['month']
            c_year = xml_response.at_xpath('//date')['year']
            c_cc_type = xml_response.at_xpath('//paymentMethod').content
            c_number = xml_response.at_xpath('//card')['number']
            c_number = '4242********4242' if c_number.blank?
            c_last_digits = c_number.last(4)
            c_name = xml_response.at_xpath('//cardHolderName').content
            card = Spree::CreditCard.where(user_id: order.user_id, month: c_month, year: c_year, cc_type: CARD_CODES[c_cc_type]||c_cc_type, last_digits: c_last_digits, name: c_name, payment_method_id: payment.payment_method_id).first_or_initialize
            puts card.inspect
            if card.id.blank?
              card.number = c_number
              card.verification_value = payment.response_code
              card.save
            end
            payment.source = card
            payment.save
          end
        end
      end
    end
  end
end
