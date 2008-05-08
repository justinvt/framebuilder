class AdminController < ApplicationController
  
  def index
    unless admin?
      redirect_to customer_login_path
    end
  end

end
