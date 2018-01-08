module Spree
	class PaymentIframe
	  include ActiveModel::AttributeMethods

	  def payment_url(order_id)
	  	url = URI("https://secure-test.worldpay.com/jsp/merchant/xml/paymentService.jsp"),
      order = Spree::Order.find_by_id(order_id)
      billing_address = order.billing_address
      builder = Nokogiri::XML::Builder.new do |xml|
        xml.doc.create_internal_subset(
          'paymentService',
          "-//Worldpay//DTD Worldpay PaymentService v1//EN",
          'http://dtd.worldpay.com/paymentService_v1.dtd'
        )
        xml.paymentService('version' => "1.4", 'merchantCode' => self.merchant_code) do
          xml.submit do
              xml.order(orderCode: order.number, installationId: self.installation_id) do 
                  xml.description do 
                      order.line_items.map(&:sku).join(',')
                  end
                  xml.paymentMethodMask do
                    xml.include(code: 'ALL')
                  end
                  xml.amount(exponent: '2', currencyCode: order.currency, value: order.total.to_money.cents)
                  xml.shopper do
                      xml.shopperEmailAddress 'admin@sandandsky.com'
                  end
                  xml.billingAddress do 
                    xml.address do 
                      xml.address1 order.street_address
                      xml.postalCode billing_address.zipcode
                      xml.city billing_address.city
                      xml.countryCode billing_address.country.iso
                    end
                  end
              end
          end
        end
      end
      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      request = Net::HTTP::Post.new(url)
      request["content-type"] = 'text/xml'
      request["cache-control"] = 'no-cache'
      request.basic_auth(self.login, self.password)
      request.body = builder.to_xml
      response = http.request(request)
      response = Nokogiri::XML(response.read_body)
      [response.at_xpath('//error').try(:content), response.at_xpath('//reference').try(:content)]
	  end
	end
end