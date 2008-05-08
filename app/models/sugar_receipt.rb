class SugarReceipt< SugarBase

  has_one :payment
  set_table_name "frame_receipts"

  def key_map
    {
      :amount=>payment.amount,
      :name=>[payment.customer.title, amount].join(" - ")
    }
  end

  def analog
    payment
  end

  def self.clone(payment)
    create(:amount=>payment.amount, :date_entered=>Time.now, :date_modified=>Time.now)
  end

  def check_relationships
    payment.credits.collect{|c| c.order}.each do |o|
      o.derive_sugar_clone if o.sugar_order.nil?
      map = { :frame_orders_ida=>o.sugar_order.id, :frame_receipts_idb=>id }
      relation = SugarOrdersReceipts.find(:first,:conditions=>map)
      SugarOrdersReceipts.create(map) if relation.nil?
    end
  end

  def ensure_consistency
    key_map.to_a.each{|pair| update_attribute(pair[0], pair[1])}
    check_relationships
    self
  end

end