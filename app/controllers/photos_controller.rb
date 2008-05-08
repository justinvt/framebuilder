class PhotosController < ApplicationController
  
  before_filter :admin_required, :only=>[:set_demo]
  layout "admin"
  
  def resize
    @frame = Frame.find(params[:frame_id])
    @size = Size.find(params[:size_id])
    @photo = session[:order].photo
    max_dim = params[:pseudonym] == "thumb.jpg" ? 100 : nil
    angle = [90,180,270].include?(params[:angle].to_i) ? params[:angle].to_i : 0
    response.headers["Content-Type"] = "image/jpeg"
    response.headers["Cache-Control"] = "max-age=5000"
    render :text => @photo.scaled_for(@size, @frame, params[:angle], max_dim).to_blob{self.format="JPEG"}
  end
  
  def canvas
    x=0
    y=20
     @photo = session[:order].photo
     response.headers["Content-Type"] = "image/jpeg"
     render :text => @photo.canvas_sample(session[:order]).to_blob{self.format="PNG"}
  end
  
  def completed
     response.headers["Content-Type"] = "image/jpeg"
     render :text => session[:order].photo.completed(session[:order]).to_blob{self.format="PNG"}
    #render :text=>session[:order].photo.completed(Order.find(80))
  end
  
  def framed
     response.headers["Content-Type"] = "image/jpeg"
     render :text => session[:order].photo.framed(session[:order]).to_blob{self.format="PNG"}
  end

  def set_demo
    @photo = Photo.find(params[:id])
    @photo.set_as_demo
    render :text=> @photo.to_json
  end
  
  def index
  end

  
end
