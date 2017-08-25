Spree::Admin::WorldpayIframeController.class_eval do
  def worldpay_refund
    if request.get?
      if @payment.source.state == 'refunded'
        flash[:error] = Spree.t(:already_refunded, :scope => 'worldpay')
        redirect_to admin_order_payment_path(@order, @payment)
      end
    elsif request.post?
      response = @payment.payment_method.refund(@payment, params[:refund_amount])
      if response.success?
        flash[:success] = Spree.t(:refund_successful, :scope => 'worldpay')
        redirect_to admin_order_payments_path(@order)
      else
        flash.now[:error] = Spree.t(:refund_unsuccessful, :scope => 'worldpay') + " (#{response.errors.first.long_message})"
        render
      end
    end
  end
end