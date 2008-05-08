require 'RMagick'
require 'gbarcode'
require 'dynamic_css'

class InterfaceController < ApplicationController

  def gradient
    params[:color].nil? ? color = "#ffff55"  : color = "#" + params[:color]
    params[:height] = 700 if params[:height].nil? 
    height = params[:height].to_i
    #params[:color].match(/[a-zA-Z0-9]{}/)
    bg = Magick::Image.new(1,height, Magick::GradientFill.new(0,0,height, 0, color,"#fff")).level(0,1.5)
    response.headers["Content-Type"] = "image/jpeg"
    render :text =>bg.to_blob{self.format="JPEG"}
  end
  
  def colors
    styles = {:hover=>{:background=>"#444"}, :selected=>{:background=>"#333"}}
    response.headers["Content-Type"] = "text/css"
    render :text => styles.to_css
  end
  
  def preview
    @order = Order.find(params[:id])
    #@order.preview
    prev =  @order.internal_preview
    response.headers["Content-Type"] = "image/jpeg"
    render :text =>Magick::ImageList.new(prev).first.to_blob{self.format="JPEG"}
  end
  
    
  def barcode
  #  response.headers["Content-Type"] = "image/jpeg"
   # Order.find(:first).get_barcode_image("abcdef")
  end

end