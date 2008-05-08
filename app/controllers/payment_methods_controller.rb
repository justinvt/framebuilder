class PaymentMethodsController < ApplicationController
  
  layout "customer"
  
  def new
    @payment_method = PaymentMethod.new
  end
  
end
