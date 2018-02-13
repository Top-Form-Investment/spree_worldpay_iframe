Deface::Override.new(:virtual_path => "spree/admin/payments/_list",
                     :name => "add_merchant_code_payment_header",
                     :insert_after => "[data-hook='payments_header'] th[3]",
                     :text => %Q{
                      <th> Merchant Code </th>
                     })
Deface::Override.new(:virtual_path => "spree/admin/payments/_list",
                     :name => "add_merchant_code_payment_row",
                     :insert_after => "[data-hook='payments_row'] td[3]",
                     :text => %Q{
                        <td class="align-center"><%= payment.payment_method.preferences[:login] if payment.payment_method.present? %></td>
                     })