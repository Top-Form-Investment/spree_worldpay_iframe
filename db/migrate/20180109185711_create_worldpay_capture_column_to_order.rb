class CreateWorldpayCaptureColumnToOrder < ActiveRecord::Migration
  def change
    add_column :spree_payments, :worldpay_capture, :boolean, default: false
  end
end
