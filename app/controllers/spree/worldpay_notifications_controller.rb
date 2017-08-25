module Spree
  class WorldpayNotificationsController < StoreController
    skip_before_filter :verify_authenticity_token

    #before_filter :authenticate

    def notify
      puts "*****************Worldpay Notify*****************"
      puts request.body
      puts "*************************************************"
      @notification = Spree::WorldpayNotification.log(request.body)
      @notification.handle!
      render :text => '[OK]'
    end

    protected
      # Enable HTTP basic authentication
      def authenticate
        authenticate_or_request_with_http_basic do |username, password|
          username == ENV['WORLDPAY_NOTIFY_USER'] && password == ENV['WORLDPAY_NOTIFY_PASSWD']
        end
      end
  end
end
