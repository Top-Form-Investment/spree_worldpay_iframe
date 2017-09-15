Rails.application.config.spree.payment_methods << Spree::Gateway::WorldpayIframe
WORLDPAY_MERCHANT_CODE = YAML.load_file("#{::Rails.root}/config/worldpay_merchant_code.yml")[::Rails.env]
WORLDPAY_MERCHANT_COUNTRY = YAML.load_file("#{::Rails.root}/config/worldpay_country_code.yml")
WORLDPAY_MERCHANT_ENTITY = YAML.load_file("#{::Rails.root}/config/worldpay_merchant_entity.yml")


