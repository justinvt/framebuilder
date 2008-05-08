class Payment < ActiveRecord::Base
  
  belongs_to :customer
  belongs_to :credit_card
  belongs_to :sugar_receipt
  has_many :credits
  has_many :orders, :through=>:credits
  
  after_create  :derive_sugar_clone
  after_update  :consistency_check
  
  def consistency_check
    derive_sugar_clone if (sugar_receipt_id.blank?)
    self.sugar_receipt.ensure_consistency unless self.sugar_receipt.blank?
  end
  
  def derive_sugar_clone
    sugar_receipt = SugarReceipt.clone(self)
    update_attribute(:sugar_receipt_id, sugar_receipt.id)
    consistency_check
  end
  
end