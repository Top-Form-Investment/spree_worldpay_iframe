Deface::Override.new(
  virtual_path: 'spree/admin/payment_methods/_form',
  name: 'Use custom form partial for worldpay iframe payment method',
  surround: '[data-hook="admin_payment_method_form_fields"]',
  text: '<% if @object.kind_of?(Spree::Gateway::WorldpayIframe) %>
           <%= render "worldpay_iframe_form", f: f %>
         <% else %>
           <%= render_original %>
         <% end %>'
)