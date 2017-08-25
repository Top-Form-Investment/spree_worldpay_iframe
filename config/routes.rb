Spree::Core::Engine.add_routes do

  namespace :admin do
    # Using :only here so it doesn't redraw those routes
    resources :orders, :only => [] do
      resources :payments, :only => [] do
        member do
          get 'worldpay_refund'
          post 'worldpay_refund'
        end
      end
    end
  end
  get "worldpay_iframe/:order_number/payment/:payment_method/success/:order_code", to: "worldpay_iframe#success", as: :worldpay_success
  get "worldpay_iframe/:order_number/payment/:payment_method/cancel/:order_code", to: "worldpay_iframe#cancel", as: :worldpay_cancel
  get "worldpay_iframe/:order_number/payment/:payment_method/failure/:order_code", to: "worldpay_iframe#failure", as: :worldpay_failure
  get "worldpay_iframe/:order_number/payment/:payment_method/pending/:order_code", to: "worldpay_iframe#pending", as: :worldpay_pending
  get "worldpay_iframe/:order_number/payment/:payment_method/error/:order_code", to: "worldpay_iframe#error", as: :worldpay_error
  post "worldpay/notify", to: "worldpay_notifications#notify", as: :worldpay_notifiy
end