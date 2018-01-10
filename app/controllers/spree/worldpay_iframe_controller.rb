module Spree
  class WorldpayIframeController < StoreController

    before_action :setup_order

   #  def success
   #    payment = Spree::Payment.new

   #    payment_method = Spree::PaymentMethod.find_by_id(params[:payment_method])
   #    payment_method.create_payment
   #    unless @order.reload.next
   #      flash[:error] = @order.errors.full_messages.join("\n")
   #      redirect_to checkout_state_path(@order.state) and return
   #    end

   #    if @order.completed?
   #      @current_order = nil
   #      flash[:notice] = Spree.t(:order_processed_successfully)
   #      flash['order_completed'] = true
   #      redirect_to spree.order_path(@order)
   #    else
   #      redirect_to checkout_state_path(@order.state)
   #    end
    # end

    def success

      unless authorized?
        flash[:notice] = Spree.t(:payment_processing_failed)
        redirect_to checkout_state_path(@order.state) and return
      end

      payment_method = Spree::PaymentMethod.find_by_id(params[:payment_method])
      payment = @order.payments.create!(
        :amount => @order.total,
        :payment_method => payment_method,
        :response_code => params[:order_code]
      )

      @order.next

      if @order.complete?
        OrderUpdateWorker.perform_async(@order.id)
        flash[:notice] = Spree.t(:order_processed_successfully)
        flash[:order_completed] = true
        redirect_to order_path(@order, :token => @order.guest_token)
      else
        redirect_to checkout_state_path(@order.state)
      end
    end

    def cancel
      puts '**************cancel**************'
      puts params.inspect
      flash[:error] = "Payment has been canceled"
      redirect_to checkout_state_path(@order.state)
    end

    def failure
      puts '**************failure**************'
      puts params.inspect
      flash[:error] = "Order has not completed due to payment failure"
      redirect_to checkout_state_path(@order.state)
    end

    def pending
      puts '**************pending**************'
      puts params.inspect
      flash[:notice] = "Order is in process"
      redirect_to checkout_state_path(@order.state)
    end

    def error
      puts '**************Error**************'
      puts params.inspect
      flash[:error] = "Order is not completed due to payment error"
      redirect_to checkout_state_path(@order.state)
    end

    private

    def authorized?
      params[:paymentStatus] == 'AUTHORISED'
    end

    def setup_order
      @order = Spree::Order.find_by_number(params[:order_number])
    end
  end
end
