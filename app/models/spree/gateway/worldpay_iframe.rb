module Spree
  class Gateway::WorldpayIframe < Gateway
  	include WorldpayIframe::PaymentRequest

    preference :login, :string
    preference :password, :string
    preference :merchant_code, :string
    preference :installation_id, :string
    preference :accepting_currency, :array
    preference :card_type, :array
    preference :country, :array
    preference :shopper_email, :string
    preference :merchant_address, :text
    preference :test_mode, :boolean

    def provider_class
      ActiveMerchant::Billing::WorldpayGateway
    end

    def provider(authorization, options = {})
      credit_card_provider(auth_credit_card(authorization), payment_currency(authorization, options))
    end

    ## change method type
    def method_type
      'worldpay_iframe'
    end

    def source_required?
      false
    end

    def eligible?(currency, country_iso)
      (self.preferences[:accepting_currency]||[]).include?(currency) && (self.preferences[:country]||[]).include?(country_iso)
    end

    def purchase(money, credit_card, options = {})
      puts "-----------purchase----------------"
      provider(credit_card, options).purchase(money, credit_card, options)
    end

    def authorize(money, credit_card, options = {})
      puts "-----------authorize----------------"
      provider(credit_card, options).authorize(money, credit_card, options)
    end

    def capture(money, authorization, options = {})
      puts "-----------capture----------------"
      provider(authorization, options).capture(money, authorization, options.merge!({authorization_validated: true}))
    end

    def refund(money, authorization, options = {})
      provider(authorization, options).refund(money, authorization, options.merge!({authorization_validated: true}))
    end

    def credit(money, authorization, options = {})
      refund(money, authorization, options)
    end

    def cancel(authorization)
      if void_refund(authorization)
        ActiveMerchant::Billing::Response.new(true, "Payment has successfully canceled", {}, {})
      else
        ActiveMerchant::Billing::Response.new(false, "Payment can't perform cancel", {}, {})
      end
    end

    def void(authorization, options = {})
      payment = Spree::Payment.find_by_response_code(authorization)
      if payment.refunds.present? && payment.refunds.map(&:amount).sum == payment.amount
        ActiveMerchant::Billing::Response.new(false, "Payment has already been refunded.", {})
      elsif payment.state == 'completed'
        ActiveMerchant::Billing::Response.new(false, "Payment can't perform 'Void' action after 'Catpure'.", {})
      else
        provider(authorization, options).void(authorization, options)
      end
    end

    private

    def options_for_card(credit_card, options)
      options[:login] = self.preferences[:login]
      options[:test] = self.preferences[:test_mode]
      options = options().merge( options )
    end

    def auth_credit_card(authorization)
      payment = Spree::Payment.find_by_response_code(authorization)
      order = payment.order
      billing_address = order.billing_address
      @currency = payment.currency
      @country_iso = billing_address.country.iso3
      payment.source
    end

    def payment_currency(authorization, options)
      if options[:currency].blank?
        options[:currency] = Spree::Payment.find_by_response_code(authorization).currency
      end
      options = options().merge( options )
    end

    def credit_card_provider(credit_card, options = {})
      gateway_options = options_for_card(credit_card, options)
      gateway_options.delete :login if gateway_options.has_key?(:login) and gateway_options[:login].nil?
      gateway_options[:inst_id] = self.preferences[:installation_id]
      ActiveMerchant::Billing::Base.gateway_mode = gateway_options[:server].to_sym
      provider_class.new(gateway_options)
    end
  end
end