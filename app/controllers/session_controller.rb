# This controller handles the login/logout function of the site.  
class SessionController < ApplicationController
  # Be sure to include AuthenticationSystem in Application Controller instead
  include AuthenticatedSystem
  layout "login"

  # render new.rhtml
  def new
  end
  
  def index
   # render :text=>params.to_json
  end

  def create
    self.current_user = User.authenticate(params[:login], params[:password])
    if logged_in?
      if params[:remember_me] == "1"
        self.current_user.remember_me
        cookies[:auth_token] = { :value => self.current_user.remember_token , :expires => self.current_user.remember_token_expires_at }
      end
       flash[:notice] = "Logged in successfully"
      if self.current_user.admin
        if  params[:origin] == "local"
          self.current_user.remember_me
          cookies[:auth_token] = { :value => self.current_user.remember_token , :expires => self.current_user.remember_token_expires_at }
          render :text=>self.current_user.remember_token
        else
          redirect_to session[:return_to] || url_for(:controller=>"frames", :action=>"index")
        end
      else
        if !session[:order].blank? and session[:order].order_status == OrderStatus.open
          session[:order].update_attribute(:customer_id,self.current_user.customer.id) unless (session[:order].blank? or self.current_user.customer.blank?)
          self.current_user.customer.cleanup_orders unless self.current_user.customer.nil?
          redirect_to cart_url
        else
          redirect_to account_url
        end
       # render :text=>"logged in"
      end
    else
      flash[:warning] = "We couldn't find a user with that email/password combo.  Click <a href="+ (forgot_password_path) + ">here</a> if you forgot your password."
      redirect_to :controller=>"customers", :action =>'login'
      #render :text=>"not logged in"
    end
  end

  def destroy
    self.current_user.forget_me if logged_in?
    cookies.delete :auth_token
    reset_session
    flash[:notice] = "You have been logged out."
    redirect_back_or_default('/')
  end
end
