require 'RMagick'
require 'fileutils'
require 'find'

class Photo < ActiveRecord::Base
  
  #validates_presence_of :path
  belongs_to :order
  serialize :colormap
  
  def directory
    
  end
  
  def versions
    sizes={}
    Size.find(:all).push(thumb).each do |s|
      name = s.title(:px).gsub(/[[:punct:]]| /,"_")
      dir = File.join("/images","photos",id.to_s,name,File.basename(url))
      dim = scaled_dimensions(s.dimensions(:px)[0],s.dimensions(:px)[1])
      sizes[name] = {:id=>s.id,:width=>dim[0].to_i,:height=>dim[1].to_i,:path=>dir,:frame_dimensions=>s.dimensions(:inches),:pixel_dimensions=>s.dimensions(:px),:name=>s.name} 
    end
    sizes
  end
  
  def intact
    File.exist?(path)
  end
  
  def smallest
    p = versions.values.sort{|a,b| (a[:width] * a[:height]) <=>  (b[:width] * b[:height]) }[0][:path]
    full = File.join(RAILS_ROOT, "public", p)
    Magick::ImageList.new(full).first
  end
  
  def largest
    versions.values.sort{|a,b| (a[:width] * a[:height]) <=>  (b[:width] * b[:height]) }[-1]
  end
  
  def self.cleanup
    Photo.find(:all).each do |p|
      unless File.exist?(p.path)
        p.order.delete
        p.destroy_and_delete
      else
        p.recheck
      end
    end
  end
  
  def recheck
    mag = magick
    update_attributes(:width=>mag.columns, :height=>mag.rows, :format=>mag.format,:filesize=>mag.filesize ,:signature=>mag.signature)
  end
  
  def destroy_and_delete
    destroy
  end
  
  def self.from_admin
    find(:all).select{|p| !p.order.nil? and  !p.order.customer.nil? and p.order.customer.user.admin }
  end
  
  def self.derelicts
    find(:all).select{|p|  p.order.nil? or p.order.customer.nil? or p.order.nil?}
  end
  
  def self.possible_demos
    (from_admin + derelicts).uniq.collect{|p| p.signature }.uniq.collect{|s| Photo.find_by_signature(s)}
  end
  
  def set_as_demo(opts={:exclusive=>true})
    if opts[:exclusive]
      self.class.update_all( "demo = '0'" )
      update_attributes(:demo=>true)
    else
      update_attributes(:demo=>true)
    end
  end
  
  def scaled_dimensions(w,h)
    scale = [w.to_f/width,h.to_f/height].max
    [width*scale,height*scale]
  end
  
  def thumb(w=100,h=100)
    scale = [ w.to_f/width, h.to_f/height ].min
    Size.new(:units=>'px',:name=>'thumb',:width=>100.to_i,:height=>100.to_i)
  end
  
  def possible_sizes
    Size.find(:all).sort{|a,b| a.area <=> b.area  }.select{|s| s.suitable_for?(width,height)}
  end

  def image_root
    dir=[RAILS_ROOT,"public","images","photos"].join("/")
     Dir.mkdir(dir) unless File.exist?(dir)
    dir
  end
  
  def self.repository
    dir= File.join(RAILS_ROOT,"public","images","photos")
     Dir.mkdir(dir) unless File.exist?(dir)
    dir
  end

  def relative_path
    dir = File.join(image_root,id.to_s)
    Dir.mkdir(dir) unless File.exist?(dir)
    dir
  end
  
  def to_path
   output=[relative_path,original_filename].join("/")
  end
  
  def url
    path.gsub((File.join(RAILS_ROOT,"public")), '')
  end
  
  def data
  end
  
  def trans_url(timestamp)
    to_path("versions/"+timestamp.gsub(/[[:punct:] ]/,"_")+"_")
  end
  
  def magick(external=false)
    if external
      Magick::ImageList.new(path).first
    else
      Magick::ImageList.new(path).first
    end
  end
  
  def self.magick(blob)
      Magick::ImageList.new.from_blob(blob)
  end
  
  def intermediary_path
    File.join(image_root,id.to_s,"intermediary.jpg")
  end
  
  def intermediary
    unless File.exist?(intermediary_path)
      magick.resize_to_fit(800,800).write(intermediary_path)
    else
      Magick::ImageList.new(intermediary_path).first
    end
  end
  
  def self.demo
    recs = self.find(:all,:conditions=>["demo = ?",true])
    recs.blank? ? Photo.find(:first) : recs[rand(recs.length)]
  end
  
  def self.update_demos
    self.find(:all, :conditions=>{:demo=>true}).each do |p|
      p.generate_versions
    end
  end
  
  def generate_versions
    versions.each do |k,v|
      dir = File.join(relative_path,k)
      Dir.mkdir(dir) unless File.exist?(dir)
      scale = [v[:width].to_f/width,v[:height].to_f/height].max
      resized= intermediary.resize(scale)
      resized.write( File.join(dir,File.basename(url)) )
    end
    sides
  end

  def self.save(order_id,photo)
    mag = self.magick(photo.read)
    new_photo=Photo.new
    new_photo.order_id = order_id
    new_photo.width = mag.columns
    new_photo.height = mag.rows
    new_photo.format = mag.format
    new_photo.signature = mag.signature
    mag.write(File.join(new_photo.relative_path,photo.original_filename))
    new_photo.update_attribute(:path, File.join(new_photo.relative_path,photo.original_filename))
    new_photo.filesize = mag.filesize
    new_photo.generate_versions
    new_photo.colormap = self.colors(new_photo.smallest)
    new_photo.save
    new_photo
  end

  def self.colors(mag)
    colormap=[]
    quantized = mag.quantize(8)
    quantized.colors.times do |c|
      color_val = Magick::Pixel.from_color(quantized.colormap(c))
      v = color_val.to_color(Magick::SVGCompliance,false,8)
      if v.scan(/[0-9]+/).length == 3
        colormap <<  v.scan(/[0-9]+/)
      else
         colormap <<  v.scan(/[0-9a-zA-Z]{2}/).collect{|col| col.hex}
      end
    end
    colormap
  end

  def scaled_for(size, frame, rotation=0, max_dim=nil)
    x_edging = frame.x_stretcher.nil? ? 0 : frame.x_stretcher * DISPLAY_DPI
    y_edging = frame.y_stretcher.nil? ? x_edging : frame.y_stretcher * DISPLAY_DPI
    unless [90,270].include?(rotation.to_i)
      end_width = size.dimensions(:px)[0] + 2 * x_edging
      end_height = size.dimensions(:px)[1] + 2 * y_edging
    else
      end_width = size.dimensions(:px)[1] + 2 * x_edging
      end_height = size.dimensions(:px)[0] + 2 * y_edging
    end
    scale = [end_width.to_f/width,end_height.to_f/height].max
    resized = magick.resize(scale)
#    scale = [90,270].include?(rotation) ? [end_width.to_f/height,end_height.to_f/width].max : [end_width.to_f/width,end_height.to_f/height].max
#    resized = [90,180,270].include?(rotation) ? magick.rotate(rotation).resize(scale) : magick.resize(scale)
    if max_dim.nil? or max_dim < 1
      resized.chop(resized.columns - x_edging, resized.rows - y_edging, x_edging, y_edging).chop(0,0,x_edging,y_edging)
    else
       output = resized.chop(resized.columns - x_edging, resized.rows - y_edging, x_edging, y_edging).chop(0,0,x_edging,y_edging)
       scale = [max_dim.to_f/output.columns,max_dim.to_f/output.rows].min
       output.resize(scale)
    end
  end
  
  def for_size(size)
    url = versions.values.select{|v| v[:id] == size.id}[0][:path]
    private_url = File.join(RAILS_ROOT, "public", url)
    Magick::ImageList.new(private_url).first
  end
  
  def sides
     sc = 0.5
     inches = 10
     darkness=0.9
     depth = 1 * DISPLAY_DPI
     w = h = inches * DISPLAY_DPI
     m = w - depth
     side_width = SIDE_WIDTH
     m=800
     canv = Magick::Image.new(m+(side_width),m+(side_width)){self.background_color="transparent"}
     sample = magick.resize(m,m)
     right = sample.crop( Magick::NorthEastGravity,depth,m, true).resize(side_width, m).modulate(darkness*0.6,1,1).blur_image(0.8, 0.4)
     right.background_color = "transparent"
     right = right.shear(0, 45)
     bottom = sample.crop(Magick::SouthWestGravity,m, depth, true).resize(m,side_width).modulate(darkness*0.3,1,1).blur_image(0.8, 0.4)
     bottom.background_color = "transparent"
     bottom = bottom.shear(-(45),0) {self.background_color="transparent"}
     canv.composite!(right,m,0, Magick::OverCompositeOp).composite!(bottom,0,m, Magick::OverCompositeOp)
     corner = canv.crop(Magick::SouthEastGravity,side_width,side_width)
     corner.write(File.join(relative_path,"corner.png"))
     right.write(File.join(relative_path,"right.png"))
     bottom.write(File.join(relative_path,"bottom.png"))
     sample.write(File.join(relative_path,"samp.png"))
  end
  
  def canvas_sample(order)
     sc = 0.7
     inches = 10
     darkness=0.9
     depth = Frame.canvas.x_stretcher * DISPLAY_DPI
     w = h = inches * DISPLAY_DPI
     m = w - depth
     dpi = order.photo.width / order.size.dimensions(:px)[0]
     canv = Magick::Image.new(m+(depth*sc),m+(depth*sc)){self.background_color="transparent"}
     sample = scaled_for(order.size, order.frame).crop(Magick::SouthEastGravity,w,h,true){self.background_color="transparent"}
     right = sample.crop( Magick::NorthEastGravity,depth,m, true).resize(depth*sc, m).modulate(darkness*0.9,1,1)
     right.background_color = "transparent"
     right = right.shear(0, 45)
     bottom = sample.crop(Magick::SouthWestGravity,m, depth, true).resize(m,depth*sc).modulate(darkness*0.5,1,1)
     bottom.background_color = "transparent"
     bottom = bottom.shear(-(45),0) {self.background_color="transparent"}
     main = sample.modulate(1.2,1,1).crop(Magick::NorthWestGravity,m,m, true){self.background_color="transparent"}
     canv.composite!(main,depth*sc,depth*sc, Magick::OverCompositeOp).composite!(main, Magick::NorthWestGravity, Magick::OverCompositeOp).composite!(right,m,0, Magick::OverCompositeOp).composite!(bottom,0,m, Magick::OverCompositeOp)
  end
  
  def completed(order)
    scales = [order.photo.width/(order.size.dimensions[0]+2*order.frame.x_stretcher), order.photo.height/(order.size.dimensions[1]+2*order.frame.y_stretcher)]
    dpi = scales.min
    width = (order.size.dimensions(:inches)[0] + 2*order.frame.x_stretcher) * dpi
    height = (order.size.dimensions(:inches)[1] + 2*order.frame.y_stretcher) * dpi
    x = order.x_offset * (order.photo.width - 2*order.frame.x_stretcher*dpi)
    y = -order.y_offset * (order.photo.height - 2*order.frame.y_stretcher*dpi) 
    magick.crop(x,y,width,height, true)
    #{:dpi=>dpi, :width=>width, :height=>height, :x=>x, :y=>y, :scales=>scales, :order=>order}.to_json
  end
  
  /#
  def write(external=false)
    save
    Dir.mkdir(relative_path) unless File.exist?(relative_path)
    Dir.mkdir(versions_path) unless File.exist?(versions_path)
    magick(external).write(to_path)
  end


  def transform(trans,idempotent=true)
    img = idempotent ? latest_version : magick
    img=trans.call(img)
    Dir.mkdir(relative_path) unless File.exist?(relative_path)
    Dir.mkdir(versions_path) unless File.exist?(versions_path)
    this_url = trans_url(Time.now.to_s)
    img.write(this_url)
    img
  end
  #/
  
  def thumb_url
    File.join('/images/photos/',id.to_s,"100px_x_100px",File.basename(path))
  end
  
  def as_tag(url)
    url.gsub("/public/",'')
  end

end
