class Frame < ActiveRecord::Base

 # To generate frame images
 # require 'rmagick'; Frame.find(:all).each{|f| f.generate(300,300,true)}
 #
 before_save :set_stretcher
 before_update :set_stretcher
 
 
  def self.floating
    self.find(:all,:conditions=>{:floating=>true, :canvas=>false})
  end
  
  def self.non_floating
    self.find(:all,:conditions=>{:floating=>false, :canvas=>false})
  end
  
   def self.canvas
    self.find(:first,:conditions=>["canvas = ?", 1])
  end
  
  def css_id
    "frame_" + id.to_s
  end
  
  def title
    name
  end
  
  def self.output_format
    "png"
  end
  
  def self.default
    self.find(:first, :conditions=>{:default=>true}) or self.find(:all)[0]
  end
  
  def self.repository
    repo = File.join(RAILS_ROOT,"public","images","frames","repo")
    Dir.mkdir(repo) unless File.exist?(repo)
    repo
  end
  
  def self.rendered_repository
    repo = File.join(RAILS_ROOT,"public","images","frames")
    Dir.mkdir(repo) unless File.exist?(repo)
    repo
  end
  
  def save_image(image, opts={})
    mag = Magick::ImageList.new.from_blob(image.read).first
    mag = opts[:preprocess].call(mag)  unless opts[:preprocess].nil?
    base = [id.to_s, name].compact.join("_").downcase
    filename = File.join(self.class.repository, base + "."+ mag.format).gsub(RAILS_ROOT,'').gsub(/^[\/\\]+/,'')
    update_attributes(:image=>(filename)) if mag.write(filename)
    generate(300,300,true,1)
  end
  
  def save_corner_shot(image, opts={})
    mag = Magick::ImageList.new.from_blob(image.read).first
    mag = opts[:preprocess].call(mag)  unless opts[:preprocess].nil?
    base = "cornershot"
    filename = File.join(image_directory, base + "."+ mag.format)
    update_attributes(:corner_shot=>(filename)) if mag.write(filename)
  end
  
  def parts_dir
    File.join(RAILS_ROOT,"public","images","frames",id.to_s)
  end
  
  def self.regenerate
   self.find(:all).each{|f| 
     f.generate(300,300,true,1) if File.exist?(f.image.to_s)
     }
  end
  
  def image_directory(is_public=false)
    d = File.join(RAILS_ROOT,"public","images","frames",id.to_s)
    unless File.exist?(d)
      Dir.mkdir(d)
    end
    is_public ? d.gsub(RAILS_ROOT,'').gsub('/public','') : d
  end
  
  def dpi_scale
    1
  end
  
  def set_stretcher
    if y_stretcher.to_i == 0 or y_stretcher.nil?
      y_stretcher = x_stretcher
    end
  end
  
  def image_path
    File.join(RAILS_ROOT,image)
  end
  
  def corner_shot_path
    corner_shot
  end
  
  def sample_image
    File.join(image_directory(true),["nw",self.class.output_format].join("."))
  end
  
  def render_onto(image,scale)
    frame = generate(image.columns, image.rows,true, scale, parts_dir, false)
    image.composite(frame, Magick::NorthEastGravity, Magick::OverCompositeOp)
  end

  def generate(width, height, shade=true, scale=1, d=parts_dir, slice=true)
    
    darkness=0.9
    edging=0
    tile_width = 40

    frame = Magick::ImageList.new(image).first
    frame_pixels = thickness * DISPLAY_DPI * scale
    scale =  frame_pixels.to_f / frame.rows.to_f 
    frame.resize!(scale)
    frame_width=frame.rows

    t = Magick::Image.new(width, frame_width){self.background_color="transparent"}
    b = Magick::Image.new(width, frame_width){self.background_color="transparent"}
    l = Magick::Image.new(frame_width, height){self.background_color="transparent"}
    r = Magick::Image.new(frame_width, height){self.background_color="transparent"}

    frame = frame.crop(Magick::NorthWestGravity, tile_width ,frame.rows)
    top_fill =  Magick::TextureFill.new(frame)
    bottom_fill =  Magick::TextureFill.new(frame.flip.modulate(darkness*0.8,1,1))
    left_fill = Magick::TextureFill.new(frame.rotate(270))
    right_fill =  Magick::TextureFill.new(frame.rotate(90).modulate(darkness,1,1))

    top_path    = Magick::Draw.new
    bottom_path = Magick::Draw.new
    left_path   = Magick::Draw.new
    right_path  = Magick::Draw.new

    top_path.define_clip_path('top_clipper') do
     top_path.polygon(1,0,width-2,0,(width-frame_width)-2,frame_width,frame_width+2,frame_width+1)
    end

    bottom_path.define_clip_path('bottom_clipper') do
      bottom_path.polygon(frame_width,0,(width-frame_width)-2,0,width,frame_width+2,0,frame_width)
    end

    top = Magick::Image.new(width, frame_width, top_fill){self.background_color="transparent"}
    bottom = Magick::Image.new(width, frame_width, bottom_fill){self.background_color="transparent"}
    right= Magick::Image.new( frame_width, height,right_fill){self.background_color="transparent"}
    left =Magick::Image.new( frame_width, height,left_fill){self.background_color="transparent"}

    top_path.clip_path('top_clipper')
    bottom_path.clip_path('bottom_clipper')
    top_path.composite(0,0,0,0,top,Magick::OverCompositeOp)
    bottom_path.composite(0,0,0,0,bottom,Magick::OverCompositeOp)
    dest=Magick::Image.new(width, height){self.background_color="transparent"}
    top_path.draw(t)
    bottom_path.draw(b)
    resultant_frame = dest.composite(right, Magick::NorthEastGravity, Magick::OverCompositeOp).composite(left, Magick::NorthWestGravity, Magick::OverCompositeOp).composite(t, Magick::NorthGravity, Magick::OverCompositeOp).composite(b, Magick::SouthGravity, Magick::OverCompositeOp)
    resultant_frame.crop!(0,0,width,height)
    image_directory
    
    if slice
    
      nw = resultant_frame.crop(Magick::NorthWestGravity,frame_width,frame_width)
      ne = resultant_frame.crop(Magick::NorthEastGravity,frame_width,frame_width)
      sw = resultant_frame.crop(Magick::SouthWestGravity,frame_width,frame_width)
      se = resultant_frame.crop(Magick::SouthEastGravity,frame_width,frame_width)
      n  = resultant_frame.crop(Magick::NorthGravity,frame_width,frame_width)
      e  = resultant_frame.crop(Magick::EastGravity,frame_width,frame_width)
      w  = resultant_frame.crop(Magick::WestGravity,frame_width,frame_width)
      s  = resultant_frame.crop(Magick::SouthGravity,frame_width,frame_width)
    
      parts = [
        {:img=>n,:filename=>"n"},
        {:img=>e,:filename=>"e"},
        {:img=>s,:filename=>"s"},
        {:img=>w,:filename=>"w"},
        {:img=>ne,:filename=>"ne"},
        {:img=>nw,:filename=>"nw"},
        {:img=>se,:filename=>"se"},
        {:img=>sw,:filename=>"sw"}
      ]
       parts.each{|p| p[:img].write(File.join(d,[p[:filename],self.class.output_format].join("."))) }
    else
     
    end
    resultant_frame.write(File.join(d,["full",self.class.output_format].join(".")))
    resultant_frame
  end
  
  def self.generate_shadows(depth,opacity=1,max_dim=800)
    
    shadow_dir = File.join('public','images','shadows')
     Dir.mkdir(shadow_dir) unless File.exist?(shadow_dir)
    img = Magick::Image.new(max_dim,max_dim){self.background_color="black"}.shadow(depth,depth,depth-1,opacity)
    east = img.crop(Magick::NorthEastGravity,depth,max_dim)
    south = img.crop(Magick::SouthWestGravity,max_dim,depth)
    southeast=img.crop(Magick::SouthEastGravity,depth,depth)
   
    parts=[
      {:img=>east, :filename=>"east.png"},
      {:img=>south, :filename=>"south.png"},
      {:img=>southeast, :filename=>"southeast.png"}
      ]
   img.write(File.join(shadow_dir,"full.png"))
   parts.each{|f| f[:img].write(File.join(shadow_dir,f[:filename])) }
    
  end
  
end
