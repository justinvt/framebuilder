class GraphicsController < ApplicationController
  
  before_filter :fix_params
  
  def output
    trans='img.'+params[:trans]
    graphic.transform(Proc.new{|img|eval(trans)}).to_blob{self.format="JPEG"}
  end
  
  def transform
     format = params[:format]
     max_size = params[:max_size].gsub(/[^0-9]/,'').to_i
     max_size = nil if max_size < 1
     graphic = Graphic.find(params[:id]).transform_by(params[:transform],format, max_size)
     headers["Content-Type"] = "image/#{format}"
     render :text => graphic.to_blob{self.format=format}
  end
  
  def rounded
     format = params[:format]
     width  = params[:dims][0].to_i
     height = params[:dims][1].to_i
     radius = params[:dims][2].to_i
     bg = params[:dims][3]
     bg_end = params[:dims][4]
     shadow = params[:dims][5]
     graphic = Graphic.rounded(:width=>width, :height=>height, :radius=> radius,:bg=>bg, :bg_end=>bg_end,:shadow=>shadow,:format=>"png")
     headers["Content-Type"] = "image/png"
     render :text => graphic.to_blob{self.format="png"}
  end
  
  def text
     headers["Content-Type"] = "image/png"
    render :text=>Graphic.text(params[:text].gsub("_"," ")).to_blob{self.format="png"}
  end
  
private

  def fix_params
     params[:format] = params[:format].downcase.gsub(/[^a-z]/,'')
     params[:dims] = params[:dims].split("_") unless params[:dims].nil?
  end

end
