
class CreditCard < ActiveRecord::Base

  belongs_to :customer
  
  def make_primary
    customer.credit_cards.each{|cc| cc.update_attributes(:primary=>false)}
    update_attributes(:primary=>true)
  end

  def obscured_number
    number.gsub(/[^0-9]/,'').gsub(/^[0-9]{1,4}/,"XXXX").split(/(....)/).join(" ")
  end
  
  def warnings
    {
      :not_found=>"That credit card was not found in your account."
    }
  end
  
  def month
    expiry.strftime("%m")
  end
  
  def year
   expiry.strftime("%Y")
  end
  
  def type
    "visa"
  end
  
  def relative_id(parent)
    parent.credit_cards.each_with_index do |cc,n|
      if cc.id == id
        break
        return n
      end
    end
  end

end