class SugarOrder < SugarBase
  
  has_many :orders
  set_table_name "frame_orders"
  
  def analog
    #YOU MUST KEEP THIS!  using "has_one" :order causes a stack error.
    # I'm assuming order is reserved
    orders[0]
  end
  
  def key_map
    {
      :name=>analog.title,
      :external_id=>analog.id,
      :frame=>analog.frame.id,
      :size=>analog.size.id,
      :rotation=>analog.rotation,
      :price=>analog.price,
      :quantity=>analog.quantity,
      :account_id=>analog.customer.sugar_user_id
    }
  end

  def self.clone(order)
    sugar_order = create(:name=>order.title,:frame=>[order.frame.name, order.frame.id].join(" - "), :date_entered=>Time.now, :date_modified=>Time.now)
    sugar_order
  end

  def consistent?
    key_map.to_a.collect{|c| self[c[0]] == c[1]}.uniq == [true]
  end

  def ensure_consistency
    unless analog.customer_id.blank? #ensure consistency if the order belongs to a customer
      key_map.to_a.each{|pair| update_attribute(pair[0], pair[1])}
      check_relationships 
    end
  end
  
  def check_relationships
    analog.customer.orders.each do |o|
      o.derive_sugar_clone if o.sugar_order.blank?
      relation = SugarOrdersAccounts.find(:first,:conditions=>{:frame_orders_ida=>o.sugar_order.id,:accounts_idb=>analog.customer.sugar_user.id})
      SugarOrdersAccounts.create(:frame_orders_ida=>o.sugar_order.id,:accounts_idb=>analog.customer.sugar_user.id) if relation.nil?
    end
  end
   
end
