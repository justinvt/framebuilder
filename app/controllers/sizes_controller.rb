class SizesController < ApplicationController
  
  before_filter :login_required, :admin_required
  layout "admin"
  
  def new
    @size = Size.new
  end

  def create
    if logged_in? and self.current_user.admin
      @size = Size.new(params[:size])
      if @size.valid?
        @size.save
         flash[:notice] = "The new size was created"
         redirect_to :action=>"index"
      else
        render :action=>:new
      end
    else
      flash[:warning] = "You don't have permission to do that"
      redirect_to :back
    end
  end
  
  def update
    @size = Size.find(params[:id])
    if @size.update_attributes(params[:size])
      flash[:notice] = "Size was edited successfully"
      redirect_to :action=>"index"
    else
      flash[:notice] = "There was an error that prevented this size from being edited"
      redirect_to :action=>"index"
    end
  end
  
  def update_demos
    Photo.update_demos
    flash[:notice] = "Demos were regenerated"
    redirect_to :action => "index"
  end
  
  def edit
    @size = Size.find(params[:id])
  end
  
  def index
    @sizes = Size.find(:all)
  end
  
  def delete
    if logged_in? and self.current_user.admin
      @size = Size.find(params[:id])
      if @size.destroy 
       flash[:notice]="Size was destroyed"
       redirect_to :action=>"index"
      else
       flash[:notice]="An error occurred"
       redirect_to :action=>"index"
      end
    else
      flash[:notice]="You don't have permission to delete things"
      redirect_to :action=>"index"
    end
  end
  
end
