class UsersController < ApplicationController
  # Be sure to include AuthenticationSystem in Application Controller instead
  include AuthenticatedSystem
  layout "login"
  
  # render new.rhtml
  def new
    @user=User.new
  end

  def create
    cookies.delete :auth_token
    # protects against session fixation attacks, wreaks havoc with 
    # request forgery protection.
    # uncomment at your own risk
    # reset_session
    params[:user][:admin] = false
    @user = User.new(params[:user])
    @user.login = @user.email
    @user.save!
    self.current_user = @user
    if session[:order] and session[:order].customer_id.blank?
      customer = Customer.create(:user_id=>@user.id, :email=>@user.email)
      session[:order].customer_id = customer.id
      session[:order].save
      redirect_to :controller=>"customers", :action=>"cart"
    else
      customer = Customer.create(:user_id=>@user.id, :email=>@user.email)
      flash[:notice] = "Thanks for signing up!"
      redirect_to :controller=>"customers", :action=>"cart"
    end
  rescue ActiveRecord::RecordInvalid
    render :action => 'new'
  end
  
  def forgot_password
  end
  
  def reset_password
    unless params[:email].blank?
      @user = User.find_by_email(params[:email])
    else
      @user = User.find_by_id(params[:id])
    end
    unless @user.nil?
      password = @user.reset_password
      Notifier.deliver_password_reset_notification(@user, password)
      flash[:notice] = 'Your password was reset.  Check your email for your new password'
      #render :text=>"ok"
      redirect_to customer_login_path
    else
      flash[:warning] = "We couldn't find any users with that email address.  Did you mistype it?"
     #  render :text=>"no-ok"
      redirect_to forgot_password_path
    end
  end

end
