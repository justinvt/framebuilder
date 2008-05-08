require 'RMagick'

class Graphic < ActiveRecord::Base
  
  def self.directory
    dir = File.join(RAILS_ROOT, "public", "images", "graphics")
    Dir.mkdir(dir) unless File.exist?(dir)
    dir
  end
  
  def self.preferred_format
    "jpg"
  end
  
  def full_path
    File.join(self.class.directory,path)
  end
  
  def magick
    Magick::ImageList.new(full_path).first
  end
  
  def with_perspective
    filename = File.join( Graphic.directory, "my_angels_tilt.jpg")
    if File.exist?(filename)
      Magick::ImageList.new(filename).first
    else
      aff = Magick::AffineMatrix.new(1,0,0.1,1,1,1)
      magick.fx('1/2').write(filename)
    end
  end
  
  def self.rounded(options={})
    options[:shadow] ||= false
    options[:radius] ||= 10
    options[:bg] ||= "ffffff"
    options[:format] ||= preferred_format
    w = options[:width]
    h = options[:height]
    r = options[:radius]
    bg = "#"+options[:bg]
    bg_end = "#"+options[:bg]
    format = options[:format]
    filename = Graphic.shape_full_filename(options)
    full_filename =  File.join( directory, filename ) 
    if File.exist?(filename)
      Magick::ImageList.new( full_filename )
    else
      imgl = Magick::ImageList.new{self.background_color="transparent"}
      imgl.new_image(w,h){self.background_color="transparent"}
      gc = Magick::Draw.new
      unless options[:bg_end].blank?
        g = Magick::GradientFill.new(0, 0, 10, 0, bg, "#" + options[:bg_end])
        grad = Magick::Image.new(1, h, g)
        gc.pattern('grad', 0, 0, grad.columns, grad.rows) {
          gc.composite(0, 0, 0, 0, grad)
        }
         gc.fill('grad')
      else
         gc.fill(bg)
      end
      
      gc.fill_opacity(1)
     
      gc.stroke_width(0)
      gc.roundrectangle(0,0,w-1,h-1,r,r)
      gc.draw(imgl)
      if options[:shadow]
        shadow = imgl.shadow(0,0,0.3,0.2)
        imgl = shadow.composite(imgl, Magick::NorthWestGravity, Magick::OverCompositeOp)
      end
      imgl.write(full_filename)
    end
  end
  
  def image_full_filename(transform,format=self.class.preferred_format,max_size=nil)
     fname = id.to_s + "/" + [id, max_size, transform.split(' ')[0]].flatten.compact.collect{|a| a.to_s}.join("_") + ".#{format.downcase}"
     dir = File.join(self.class.directory, File.dirname(fname))
     Dir.mkdir(dir) unless File.exist?(dir)
     fname
  end
  
  def Graphic.shape_full_filename(options={})
     fname = "rendered" + "/" + options.reject{|k,v| k.to_sym == :format }.values.collect{|o| o.to_s.gsub(/[^0-9a-zA-Z]/,'')}.join("_") + ".#{options[:format].downcase}"
     dir = File.join(directory, File.dirname(fname))
     Dir.mkdir(dir) unless File.exist?(dir)
     fname
  end
  
  def transform_by(string,format,max_size=nil)
    fname = image_full_filename(string,format,max_size)
    full_filename =  File.join( self.class.directory, fname ) 
    if File.exist?( full_filename )
      Magick::ImageList.new( full_filename )
    else
      output = magick
      case string.split(' ')[0]
        when "polaroid" : output = output.polaroid
      end
      max_size.blank? ? output.write( full_filename ) : output.resize_to_fit(max_size,max_size).write( full_filename )
    end
  end

  def self.text(words="test",color1="#000",color2="#fff")
    h=30
    w=words.length*15
    img = Magick::ImageList.new
    img.new_image(w,h){self.background_color="transparent"}
    sample = Magick::Draw.new
    sample.stroke('transparent')
    sample.font_family('Lucida')
    g = Magick::GradientFill.new(0, 0, h, 0, '#fff', "#666")
    grad = Magick::Image.new(1, h, g)
    sample.pattern('grad', 0, 0, grad.columns, grad.rows) {
      sample.composite(0, 0, 0, 0, grad)
    }
    sample.fill('grad')
    sample.pointsize(24)
    sample.font_style(Magick::NormalStyle)
    sample.text(0,20, words)
    sample.draw(img)
    img
  end

end