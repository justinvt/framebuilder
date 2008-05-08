require 'open-uri'
class CustomersController < ApplicationController

  before_filter :set_params, :ensure_user_has_customer
  before_filter  :login_required, :except=>[:login]

  layout :layout
  helper CreditCardsHelper
  
  def layout
    if action_name == "login"
      "login"
    else
      "customer"
    end
  end
  
  def test
    render :text=>self.current_user.customer.orders[params[:id].to_i].to_json
  end
  
  def reset
    session = {}
  end
  


  def login
    unless session[:order].blank? or params[:frame].blank?
      session[:order].update_attributes(:quantity=>params[:frame][:quantity].to_i, :order_status_id=>OrderStatus.unpaid.id)
    end
    if customer?
      self.current_user.customer.cleanup_orders
      redirect_to cart_path
    elsif admin?
      reset_session
      redirect_to customer_login_path
    else
      @user=User.new
    end
  end

  def cart
   #unless session[:order].blank?
    #  session[:order].update_attributes!(:order_status_id => OrderStatus.unpaid.id) if (session[:order].order_status == OrderStatus.open)
    #end
    @customer = self.current_user.customer
    #render :text=>@customer.id
  end

  def checkout
    @customer = self.current_user.customer
    @credit_card = @customer.primary_payment_method || CreditCard.new(params[:credit_card])
    unless params[:orders].blank?
      params[:orders].each do |id, attributes|
        @customer.orders.find(:first, :conditions=>{:id=>id}).update_attributes(:quantity=>attributes[:quantity].to_i)
      end
    end
    #if @customer.has_valid_billing_address?
      #if @customer.has_valid_payment_method?
        session[:goal] = nil
        render :template => "customers/quick_checkout"
      #else
      #  session[:goal] = url_for(:controller=>'customers', :action=>'checkout')
      #  redirect_to :controller=>'credit_cards', :action=>'new'
      #end
    #else
    #  flash[:notice] = "We need a valid mailing address first..."
    #  session[:goal] = @customer.has_valid_payment_method? ?  url_for(:controller=>'customers', :action=>'checkout') :  url_for(:controller=>'credit_cards', :action=>'new')
    #  redirect_to :controller=>'customers', :action=>'info'
    #end
  end
  
  def quick_checkout
    @customer = self.current_user.customer
    params[:credit_card][:customer_id] = @customer.id
    @credit_card = CreditCard.new(params[:credit_card])
    @customer.update_attributes(params[:customer])
    if @customer.has_valid_billing_address?
      if @credit_card.valid?
        @credit_card.primary = 1
        @credit_card.expiry = Date.civil(params[:expiry_year].to_i,params[:expiry_month].to_i,1)
        @credit_card.save
        @credit_card.make_primary
        payment = @customer.charge(1)
        if payment
          @orders = @customer.unpaid
          @orders.each{|o| 
          if o.update_attributes(:order_status_id=>OrderStatus.paid.id)
            #order_errors << o.id 
            Credit.create(:order_id=>o.id, :amount=>o.price, :payment_id =>payment.id)
          end
          }
           payment.reload.consistency_check
          flash[:notice]= "Your payment was successful.  You'll be receiving email confirmation shortly"
          redirect_to :action=>"cart"
          return
        else
          flash[:warning] = "We could not process this credit card.  Please check your information and try again."
         render :template=>"customers/quick_checkout"
          return
        end
      else
        render :action=>"customers/quick_checkout"
        return
      end
    else
        render :action=>"checkout"
        return
    end
    
  end
  
  def billing
    @customer = self.current_user.customer
  end

  def info
    @customer = self.current_user.customer
  end

  def remove
   @customer = self.current_user.customer
   @order = Order.find(params[:id])
   if @order.customer == @customer
      if params[:status] == "remove"
        new_status = OrderStatus.deleted.id
      elsif params[:status] == "restore"
        new_status = OrderStatus.unpaid.id
      end
      if @order.update_attributes(:order_status_id=>new_status)
        flash[:notice] = (params[:status]=="remove" ? "That item was removed from your cart" : "That item was returned to your cart")
        redirect_to :action=>:cart
      else
         flash[:notice] = "There was an error"
         redirect_to :action=>:cart
      end 
  end
  end

  def show
    @customer = self.current_user.customer
    respond_to do |format|
      format.html
      format.js {render :text=>('var customer_address = '+@customer.address.to_json)}
    end
  end

  def index
    if !self.current_user.customer.nil?
        @customer =  self.current_user.customer
      render :action=>"show"
    end
  end

  def update
    #params[:customer][:zip] = nil
    if customer?
      @customer = self.current_user.customer
      if @customer.update_attributes!(params[:customer])
        unless @customer.zip.blank?
          @customer[:distance] = @customer.distance
        end
        #flash[:notice] = "Your info was successfully updated"
        respond_to do |format|
          #format.html {redirect_to(session[:goal].blank? ? {:action=>"index"} : session[:goal])}
          format.js {render :text=>@customer.to_json}
        end
      else
        render :action=>"info"
      end
    elsif admin?
       @customer = Customer.find(params[:id])
    end
  end

  def charge
    @customer = self.current_user.customer
    @orders = Order.find(params[:order])
    total = @orders.collect{|o| o.price}.sum
    order_errors =[]
    if @customer.test_charge(total)
      payment =  @customer.charge(total)
      if payment
        @orders.each{|o| 
          if o.update_attributes(:order_status_id=>4)
            order_errors << o.id 
            Credit.create(:order_id=>o.id, :amount=>o.price, :payment_id =>payment.id)
          end
          }
        #payment = Payment.find(:first)
        #Notifier.deliver_payment_notification(payment)
        payment.reload.consistency_check
      end
      flash[:notice]="Your order has been accepted.  We will send you an email confirmation in a sec."
      redirect_to :action=>"index"
    else
     # render :action=>"checkout"
    end
    # render :text=>@orders.inspect
  end

private

  def set_params
    if customer?
      if self.current_user.customer.nil?
      
      end
    end
    if logged_in? and !self.current_user.admin and !self.current_user.customer.nil?
      params[:customer_id] = self.current_user.customer.id
    else
      params[:customer_id] = nil
    end
  end
  
end
