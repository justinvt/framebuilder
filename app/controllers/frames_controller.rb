require 'active_record_addons'
class FramesController < ApplicationController
  
  layout "admin"
  
  before_filter :login_required, :admin_required

  def new
    @frame = Frame.new
  end

  def create
    if logged_in? and self.current_user.admin
      @frame = Frame.new(params[:frame])
      @frame.name = params[:image][:file].original_filename.split(".")[0].gsub(/[^a-zA-Z0-9]/," ") if params[:frame][:name].blank?
      @frame.y_stretcher = @frame.x_stretcher
      if @frame.valid?
        @frame.save
        @frame.save_image(params[:image][:file], {:name=>@frame.name})
        @frame.save_corner_shot(params[:image][:corner_shot]) unless params[:image][:corner_shot].blank?
        flash[:notice]="Frame was created"
        redirect_to :action=>"index"
      else
        render :action=>"new"
      end
    else
      flash[:warning]= "You don't have permission to do that"
      redirect_to :back
    end
  end
  
  def update
    @frame = Frame.find(params[:id])
    original_thickness = @frame.thickness
    if @frame.update_attributes(params[:frame])
      unless params[:image][:file].blank?
        @frame.save_image(params[:image][:file],{ :name=>@frame.name, :preprocess=>Proc.new {|img| img.rotate!(90) } })
      else
       @frame.generate(300,300,true,1) unless original_thickness == @frame.thickness
      end
      @frame.save_corner_shot(params[:image][:corner_shot]) unless params[:image][:corner_shot].blank?
       flash[:notice]="Frame was updated"
       redirect_to :action=>"show", :id=>@frame.id
    else
      flash[:warning]="An error occurred that prevented the frame from being updated"
      redirect_to :action=>"show", :id=>@frame.id
    end
  end
  
  def regenerate_all
    Frame.regenerate
    flash[:notice] = "Frames were regenerated"
    redirect_to :action => "index"
  end
  
  def delete
    if logged_in? and self.current_user.admin
      @frame = Frame.find(params[:id])
      if @frame.destroy 
       flash[:notice]="Frame was destroyed"
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
  
  def edit
    @frame = Frame.find(params[:id])
  end
  
  def index
    @frames = Frame.find(:all)
  end
  
  def show
    @frame =  Frame.find(params[:id])
  end

end