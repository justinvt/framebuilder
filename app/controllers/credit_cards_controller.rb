class CreditCardsController < ApplicationController
  
  before_filter :login_required
  
  layout "customer"
  
  def index
    @customer = self.current_user.customer
  end
  
  def new
    @customer = self.current_user.customer
    @credit_card = CreditCard.new(:customer_id=>@customer)
     respond_to do |format|
       format.html {}
    end
  end

  def create
    @customer = self.current_user.customer
    @credit_card = CreditCard.new(params[:credit_card])
    @credit_card.customer_id = @customer.id
    @credit_card.number.gsub!(/[^0-9]/,'')
    respond_to do |format|
      if @credit_card.valid?
        @credit_card.save
        flash[:notice] = "The card was added and set as your primary payment method."
        format.html {redirect_to session[:goal] || url_for(:action=>'index')}
      else
        format.html {render :action=>"edit"}
      end
    end
  end

  def update
    @customer = self.current_user.customer
    @credit_card =  @customer.credit_cards[params[:id].to_i]
    unless @credit_card.nil?
      respond_to do |format|
        if @credit_card.update_attributes(params[:credit_card])
          format.html {redirect_to :action=>"index"}
        else
           format.html {render :action=>"edit"}
        end
      end
    else
      flash[:warning] =  CreditCard.warnings[:not_found]
      redirect_to :back
    end
  end
  
  def edit
    @customer = self.current_user.customer
    @credit_card = @customer.credit_cards.find(params[:id])
     respond_to do |format|
       format.html {render :action=>"edit"}
    end
  end
  
  def delete
    @customer = self.current_user.customer
    @credit_card = @customer.credit_cards[params[:id].to_i]
    unless @credit_card.nil?
      if @credit_card.destroy
        flash[:notice]="You card was successfully deleted."
        redirect_to :action=>:index
      else
        flash[:warning]= "An error prevented us from deleting your card."
         redirect_to :action=>:index
      end
    else
       flash[:warning]= CreditCard.warnings[:not_found]
        redirect_to :action=>:index
    end
  end
  
  def primary
    @customer = self.current_user.customer
    @credit_card = @customer.credit_cards[params[:id].to_i]
    if @credit_card.make_primary
      flash[:notice] = "This card was set as your primary payment method"
    else
       flash[:warning] = "This card was not set as your primary card"
    end
    redirect_to :back
  end

  def show
    edit
  end

end
