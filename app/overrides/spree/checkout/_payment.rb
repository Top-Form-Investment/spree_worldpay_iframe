Deface::Override.new(
  virtual_path: 'spree/checkout/_payment',
  name: 'Add worldpay script on payment page',
  insert_before: '[data-hook="payment_fieldset_wrapper"]',
  text: '<%= render "spree/checkout/payment/worldpay_checkout"%>'
)