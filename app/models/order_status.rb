class OrderStatus < ActiveRecord::Base
   
  set_table_name "order_statuses"
  has_many :orders
  
  def self.unpaid
    self.find_by_name("unpaid")
  end
  
  def self.deleted
    self.find_by_name("deleted")
  end
  
  def self.paid
    self.find_by_name("paid")
  end
  
  def self.shipped
    self.find_by_name("shipped")
  end
  
  def self.printed
    self.find_by_name("printed")
  end
  
  def self.open
    self.find_by_name("open")
  end
  
  def self.is_(state)
    self.find_by_name(state)
  end

end
