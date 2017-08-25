Spree::BaseHelper.class_eval do

	def redirect_url(type, order_code, payment_method_id)
		url = case type
		when 'success'
		  worldpay_success_path(current_order.number, payment_method_id, order_code)
		when 'cancel'
		  worldpay_cancel_path(current_order.number, payment_method_id, order_code)
		when 'failure'
		  worldpay_failure_path(current_order.number, payment_method_id, order_code)
		when 'pending'
		  worldpay_pending_path(current_order.number, payment_method_id, order_code)
		when 'error'
			worldpay_error_path(current_order.number, payment_method_id, order_code)
		else
			''
		end
		request.base_url+url
	end

end