class OrdersController < ApplicationController
 
  layout :layout
  before_filter :set_vars, :only=>[:size,:kind,:finalize]
  
  def layout
   if ["kind","size", "finalize"].include?(params[:action])
     "framer"
    elsif ["new"].include?(params[:action])
       "flash"
    elsif customer?
      "customer"
    elsif admin?
      "work_order"
    end
  end

  def new
  end
  
  def index
    if admin?
      @orders = Order.find(:all)
    elsif customer?
      @customer = self.current_user.customer
      if params[:scope].blank?
       @orders = self.current_user.customer.orders
      else
        case params[:scope]
          when "paid":  @orders = Order.find(:all, :conditions=>{:customer_id=>self.current_user.customer.id, :order_status_id=>OrderStatus.paid})
          when "unpaid":  @orders = Order.find(:all, :conditions=>{:customer_id=>self.current_user.customer.id, :order_status_id=>OrderStatus.unpaid})
          when "shipped":  @orders = Order.find(:all, :conditions=>{:customer_id=>self.current_user.customer.id, :order_status_id=>OrderStatus.shipped})
          when "deleted":  @orders = Order.find(:all, :conditions=>{:customer_id=>self.current_user.customer.id, :order_status_id=>OrderStatus.deleted})
        end
      end
    end
  end
  
  def show
    if admin?
      @order = Order.find(params[:id])
      output = render_to_string :template=>"orders/show.mab", :layout=>"work_order.mab"
      filename = File.join(@order.directory,@order.class.info_sheet_name)
      #unless File.exist?(filename)
      open(filename, "wb") do |data|
        data.write(output)
      end 
      #end
      render :text=>output
    else
      redirect_to customer_login_path
      #return false
    end
  end
  
  def create
   @order = Order.create(:frame_id =>Frame.default.id, :size_id=>Size.default.id,:x_offset=>0, :y_offset=>0, :order_status_id=>OrderStatus.open.id)
   @photo = Photo.save(@order.id,params[:photo][:file])
   render :text=>@order.to_xml
  end
  
  def demo
    redirect_to :action=>"size"
  end
  
  def prepare
    set_photo
    #set_vars
    redirect_to :action=>"size"
  end
  
  def load_by_id
    if self.current_user == :false
      session[:return_to] = url_for(:controller=>"orders", :action=>"load_by_id", :id=>params[:id])
      flash[:warning] = "You must login first to perform this action"
      redirect_to login_path
    elsif self.current_user.admin or (logged_in? and self.current_user.customer.orders.collect{|o|o.id}.include?(params[:id].to_i))
      session[:order] = Order.find(params[:id])
      session[:working_id] = session[:order].id
      redirect_to  :action=>:size
    else
      redirect_to :controller=>:orders, :action=>:new
    end
  end
  
  def download
    if admin?
      order = Order.find(params[:id])
      send_file order.photo.path
    else
      redirect_to :controller=>:orders, :action=>:new
    end
  end

  def size
    #set_photo
    if logged_in? and !self.current_user.admin and !session[:order].nil? and !self.current_user.customer.blank?
      session[:order].update_attributes(:customer_id=>self.current_user.customer.id)
    #elsif !session[:customer].blank?
      #session[:order].update_attributes(:customer_id=>session[:customer].id)
    else
      #customer = Customer.create(:ip=>request.remote_ip)
      #session[:order].update_attributes(:customer_id=>customer.id)
      #session[:customer] =  customer
    end
    #    set_vars

  end

  def kind
    unless params[:frame].nil?
     # id = params[:frame][:size]
     # size = Size.find(id)
      #unless params[:frame][:frame_id].blank?
        # frame = Frame.find( params[:frame][:frame_id]) 
       #  session[:order].frame_id = frame.id
      #end
     # session[:order].size_id = size.id
      #session[:order].x_offset = params[:frame][:x_offset]
      #session[:order].y_offset = params[:frame][:y_offset]
     # session[:order].rotation = params[:frame][:rotation]
      #session[:order].update
    end
    @frames= Frame.find(:all)
  end

  def finalize

   # session[:order].order_status_id = OrderStatus.unpaid.id if (session[:order].order_status == OrderStatus.open)
    unless params[:frame].nil?
     # session[:order].frame_id = params[:frame][:frame_id]
    #  session[:order].x_offset = params[:frame][:x_offset]
    #  session[:order].y_offset = params[:frame][:y_offset]
     # session[:order].rotation = params[:frame][:rotation]
     # session[:order].quantity = 1
    end
     #session[:order].update
  end
  
  def update
    set_vars
    unless params[:frame].nil?
      session[:order].frame_id = params[:frame][:frame_id] unless params[:frame][:frame_id].blank?
      session[:order].size_id  = params[:frame][:size_id]  unless params[:frame][:size_id].blank?
      session[:order].x_offset = params[:frame][:x_offset]  unless params[:frame][:x_offset].blank?
      session[:order].y_offset = params[:frame][:y_offset]  unless params[:frame][:y_offset].blank?
      session[:order].rotation = params[:frame][:rotation]  unless params[:frame][:rotation].blank?
      session[:order].save!
   
     
    end
    render :text=>session[:order].to_json
  end



  def set_vars
    unless session[:working_id].blank?
      session[:order] = Order.find(session[:working_id])
    else
      redirect_to demo_path
    end
  end

  def set_photo
    if params[:id]=="demo"
       session[:demo] == true
      # @photo = Photo.demo
      # if Photo.demo.order.blank?
      #   session[:order] = Order.default
      # else
      #   session[:order] = (Photo.demo.order || Order.new(:size_id=>1, :frame_id=>1))
      # end
      @photo = Photo.demo
      unless Order.exists?(@photo.order_id)
        @order = Order.create(:frame_id=>1, :size_id=>1,:order_status_id=>OrderStatus.demo)
        @photo.update_attributes(:order_id=>@order.id)
        session[:order] = @order
      else
        session[:order] = @order =  @photo.order
      end
       session[:working_id] = @order.id
    else
      @order = Order.find(params[:id])
      session[:working_id] = @order.id
      session[:order] = @order
    end

  end


end
