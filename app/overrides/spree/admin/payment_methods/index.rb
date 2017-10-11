Deface::Override.new(:virtual_path => "spree/admin/payment_methods/index",
                     :name => "add_merchant_code_header",
                     :insert_after => "[data-hook='admin_payment_methods_index_headers'] th[3]",
                     :text => %Q{
                      <th> Merchant Code </th>
                     })
Deface::Override.new(:virtual_path => "spree/admin/payment_methods/index",
                     :name => "add_merchant_code_row",
                     :insert_after => "[data-hook='admin_payment_methods_index_rows'] td[3]",
                     :text => %Q{
                        <td class="align-center"><%= method.preferences[:merchant_code] %></td>
                     })