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

        def setup_api_call(country_iso, currency)
          @country_iso = country_iso
          @currency = currency
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
          order = Spree::Order.find_by_id(order_id)
          billing_address = order.billing_address
          http, request = setup_api_call(billing_address.country.iso3, order.currency)
          order_code = "#{order.number}-#{Time.now.to_i}"
          token_reference = 'TOK'+"#{order.number}_#{Time.now.to_i}"
          builder = build_request do |xml|
            xml.submit do
              xml.order(orderCode: order_code, installationId: self.preferences[:installation_id]) do
                xml.description order.line_items.map(&:sku).join(',')
                xml.amount(exponent: '2', currencyCode: order.currency, value: order.total.to_money.cents)
                xml.orderContent order.line_items.map(&:sku).join(',')
                xml.paymentMethodMask do
                  xml.include(code: 'ALL')
                end
                xml.shopper do
                  xml.shopperEmailAddress order.email
                  xml.authenticatedShopperID self.preferences[:merchant_code]
                end
                xml.billingAddress do
                  xml.address do
                    xml.address1 order.street_address
                    xml.postalCode billing_address.zipcode
                    xml.city billing_address.city
                    xml.countryCode billing_address.country.iso
                  end
                end
                xml.createToken(tokenScope: 'shopper') do
                  xml.tokenEventReference token_reference
                  xml.tokenReason 'Subscription'
                end
              end
            end
          end
          request.body = builder
          response = http.request(request)
          puts request.body.inspect
          puts response.read_body.inspect
          response = Nokogiri::XML(response.read_body)
          preferred_methods = (self.preferences[:card_type]||[]).select{|s| s.present?}
          preferred_method = preferred_methods.size == 1 ? preferred_methods.first : ''
          [order_code, response.at_xpath('//error').try(:content), response.at_xpath('//reference').try(:content), preferred_method]
        end

        def order_inquiry(order_code)
          order_number = order_code.split('-')
          order = Spree::Order.find_by_number(order_number)
          billing_address = order.billing_address
          http, request = setup_api_call(billing_address.country.iso3, order.currency)
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
            puts "-------------Void-Refund--------------------"
            payment = Spree::Payment.find_by_response_code authorization
            order = payment.order
            billing_address = order.billing_address
            http, request = setup_api_call(billing_address.country.iso3, order.currency)
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

        def create_payment_source(order_id, event_type, xml_response = nil)
          order = Spree::Order.find order_id
          order_code = xml_response.at_xpath('//orderStatusEvent')['orderCode']
          payment = Spree::Payment.where(response_code: order_code).last
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
            c_token = xml_response.at_xpath('//paymentTokenID').try(:content)
            card = Spree::CreditCard.where("user_id = ? AND month = ? AND year = ? AND cc_type = ? AND last_digits = ? AND name = ?  AND payment_method_id = ? ",order.user_id, c_month, c_year, CARD_CODES[c_cc_type]||c_cc_type, c_last_digits, c_name, payment.payment_method_id).first
            if card.blank?
              card = Spree::CreditCard.new(number: c_number, verification_value: payment.response_code, user_id: order.user_id, month: c_month, year: c_year, cc_type: CARD_CODES[c_cc_type]||c_cc_type, last_digits: c_last_digits, name: c_name, payment_method_id: payment.payment_method_id, worldpay_gateway_token: c_token)
              card.save
            elsif card.worldpay_gateway_token.blank? && c_token.present?
              card.worldpay_gateway_token = token
              card.save
            end
            payment.source = card
            payment.save
          end
        end

        def create_recurring_payment(order_id, payment_id)
          order = Spree::Order.find order_id
          payment = Spree::Payment.find payment_id
          token = payment.source.worldpay_gateway_token
          order_code = "#{order.number}-#{Time.now.to_i}"
          billing_address = order.billing_address
          http, request = setup_api_call(billing_address.country.iso3, order.currency)
          builder = build_request do |xml|
            xml.submit do
              xml.order(orderCode: order_code, installationId: self.preferences[:installation_id]) do
                xml.description 'Recurring Payment'
                xml.amount(exponent: '2', currencyCode: order.currency, value: order.total.to_money.cents)
                xml.paymentDetails do
                  xml.tag!('TOKEN-SSL', 'tokenScope' => 'shopper', 'captureCvc' => false) do 
                    xml.paymentTokenID token
                  end
                  xml.session(shopperIPAddress: order.last_ip_address, id: order.number)
                end
                xml.shopper do
                  xml.shopperEmailAddress order.email
                  xml.authenticatedShopperID self.preferences[:merchant_code]
                end
              end
            end
          end
          request.body = builder
          response = http.request(request)
          puts request.body.inspect
          puts response.read_body.inspect
          response = Nokogiri::XML(response.read_body)
          if response.at_xpath('//lastEvent').content == 'AUTHORISED'
            payment.update(response_code: order_code)
          else
            false
          end
        end
      end
    end
  end
end