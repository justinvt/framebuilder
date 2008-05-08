# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  include AuthenticatedSystem
  
  #helper :all # include all helpers, all the time

  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  #protect_from_forgery # :secret => '07349d9e841b9bcc5e4b849ee0a1c8fe'
  def admin_required
    unless self.current_user.blank?
      if self.current_user.admin?
        return true
      else
        flash[:warning] = "You don't have permission to do that"
        redirect_to :controller=>:pages, :action=>:index ,:id=>'home'
      end
    else
      flash[:warning] = "You don't have permission to do that"
      redirect_to :controller=>:pages, :action=>:index ,:id=>'home'
    end
  end
  
  def ensure_user_has_customer
    if customer?
     if session[:order] and session[:order].customer_id.blank?
        customer = Customer.create(:user_id=>self.current_user.id, :email=>self.current_user.email)
        session[:order].customer_id = customer.id
        session[:order].save
      end
    end
  end

end
