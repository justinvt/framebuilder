require 'active_merchant'
require 'open-uri'

class Customer < ActiveRecord::Base
  
 # include ActiveMerchant::Billing
  
  has_many :orders
  has_many :payment_methods
  has_many :credit_cards
  has_many :photos, :source=>:orders
  belongs_to :user
  belongs_to :sugar_user
  has_many :payments
  
  after_update  :consistency_check
  after_create  :derive_sugar_clone
  
  def title
    if first_name.blank? and last_name.blank? 
      "(name not specified)"
    else
      [first_name, last_name].join(" ")
    end
  end
  
  def address
    {
      :first_name=>first_name, 
      :last_name =>last_name, 
      :address_1=>address_1, 
      :address_2=>address_2,
      :city=>city,
      :state=>state,
      :zip=>zip
    }
  end
  
  def distance(opts={})
    return false if zip.blank?
    our_zip = "19123"
    from = "19008"
    zip_resource = "http://geocoder.us/service/distance"
    calculator = zip_resource + "?zip1=#{our_zip}&zip2=#{from}"
    begin
      u = open(calculator)
      response = u.read()
      result  = response.split("=")[-1].gsub(/[^0-9\.]+/,'').to_f
      return result
    rescue
      return "aaaa"
    end
  end
  
  def registered
    !email.blank?
  end
  
  def unpaid
    orders.select{|o| o.order_status == OrderStatus.unpaid }
  end
  
  def cart
    unpaid
  end
  
  def paid
    orders.select{|o| o.order_status == OrderStatus.paid }
  end
  
  def trash
    orders.select{|o| o.order_status == OrderStatus.deleted }
  end
  
  def orders_marked(status)
    orders.select{|o| o.order_status.name == status.to_s.downcase }
  end
  
  def shipped
    orders.select{|o|  o.order_status.name == "shipped" }
  end
  
  def cleanup_orders
    trash.each do |litter|
      litter.destroy if litter.updated_at < 7.days.ago
    end
  end
  
  def has_trash?
    Order.find(:all,:conditions=>{:customer_id=>id, :order_status_id=>OrderStatus.deleted}).size > 0
  end
  
  def has_valid_payment_method?
    credit_cards.size > 0
  end
  
  def has_valid_billing_address?
    needs = [address_1, city, state, zip]
    needs.length == needs.reject{|c| c.blank?}.length
  end
  
  def amount_owed
    unpaid.collect{|o| o.price}.sum
  end

  def ready_to_order?
    has_valid_payment_method? and has_valid_billing_address?
  end

  def primary_payment_method
    CreditCard.find(:first, :conditions=>{:customer_id=>id, :primary=>true}) || credit_cards[0]
  end

  def test_charge(amount)
    true
  end

  def charge(amount)
    payment_method = primary_payment_method
    amount_in_cents = amount*100
    creditcard = ActiveMerchant::Billing::CreditCard.new(
      :type       =>   payment_method.type,
      :verification_value => "455",
      :number     =>  (ActiveMerchant::Billing::Base.mode == :test ? "4111111111111111" : payment_method.number),
      :month      =>  payment_method.month,
      :year       =>  payment_method.year,
      :first_name =>  payment_method.customer.first_name,
      :last_name  =>  payment_method.customer.last_name
    )
    if creditcard.valid?
      gateway = ActiveMerchant::Billing::PayflowGateway.new(
        :vendor=>PAYPAL[:login],:login=>PAYPAL[:login], :user=>PAYPAL[:user],:password=>PAYPAL[:password], :partner=>'PayPal'
      )
      response = gateway.authorize(amount_in_cents, creditcard)
      if response.success?
        gateway.capture(amount_in_cents, response.authorization)
        payment = Payment.create(:customer_id=>id, :amount=>amount, :credit_card_id => payment_method.id, :transaction_id=>response.params["pn_ref"] )
        #puts response.to_json
        return payment
      else
        raise StandardError, response.to_json
        #return false
      end
    else
       raise StandardError, creditcard.to_json
       #return false
    end
  end

  def consistency_check
    unless user.blank? or email.blank?
      user.update_attributes(:email=>email,:login=>email)
    end
    self.sugar_user.ensure_consistency
  end
  
  def derive_sugar_clone
    sugar_user = SugarUser.clone(self)
    update_attribute(:sugar_user_id, sugar_user.id)
  end
  
end
