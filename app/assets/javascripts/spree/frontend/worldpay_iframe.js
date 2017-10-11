function hide_order_now(obj){
    if($(obj).parent().attr('data-payment-type') == 'Spree::Gateway::WorldpayIframe'){
        $("form#checkout_form_payment").find("input[type='submit']").addClass('hide');
        open_payment_page($(obj).val());
    }else{
        $("form#checkout_form_payment").find("input[type='submit']").removeClass('hide');
    }
}

function open_payment_page(method_id){
    console.log(method_id);
    if($('#custom-html-'+method_id).find('#wp-cl').size() == 0){
        //initialise the library and pass options
        libraryObject = new WPCL.Library();
        libraryObject.setup(customOptions[method_id]);
    }
}