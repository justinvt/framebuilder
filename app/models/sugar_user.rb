class SugarUser < SugarBase
  
  has_one :customer
  set_table_name "accounts"
  
  def analog
    customer
  end

  def key_map
    {
      :name=>analog.title,
      :shipping_address_street=>analog[:address_1], 
      :shipping_address_city=>customer[:city],
      :shipping_address_state=>customer[:state],
      :shipping_address_postalcode=>customer[:zip],
      :phone_office=>customer[:phone],
      :external_id => customer.id,
      :mainemail=>customer.email
    }
  end

  def self.clone(customer)
    create(:name=>[customer.first_name,customer.last_name].join(" "), :date_entered=>Time.now, :date_modified=>Time.now)
  end

  def consistent?
   key_map.to_a.collect{|c| self[c[0]] == c[1]}.uniq == [true]
  end

  def ensure_consistency
    key_map.to_a.each{|pair| update_attribute(pair[0], pair[1])}
    self
  end

end