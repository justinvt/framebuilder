require 'RMagick'
require 'gbarcode'
require 'ftools'

class Order < ActiveRecord::Base
  
  belongs_to :customer
  belongs_to :order_status
  belongs_to :batch
  has_one :photo
	belongs_to :size
	belongs_to :frame
	has_many :credits
	belongs_to :sugar_order

  after_update  :consistency_check
  after_create  :reset_directory
	#before_update  :set_status
	
	def backup
	  dirname =  File.join(RAILS_ROOT,"backup","orders")
    Dir.mkdir(dirname) unless File.exist?(dirname)
    dirname
	end
	
	def self.default
	  new(:size_id=>Size.find(:first), :frame_id =>Frame.find(:first))
	end
	
	def self.ready_for_batching
	  all_paid#.select{|o| o.intact}
	end
	
	def self.degenerate
	  all_paid.reject{|o| o.intact}
	end
	
	def reset_directory
	  if File.exist?(directory)
	    File.move(directory,backup)
	  end
	end
	
	def self.print_format
	  "jpg"
	end
	
	def self.preview_size
	  100
	end
	
	def self.waste
	  0.2 # <= the anticipated amount of materials that will be wasted during assembly
	end
	
	def self.preview_filename
	  'preview.jpg'
	end
	
	def self.final_filename
	  ['final',print_format].join(".")
	end
	
	def self.info_sheet_name
	  'info.html'
	end
		
	def price
	  update_attribute(:quantity,1)  if quantity.to_i < 1
		(size.price.to_f + (( size.dimensions(:inches)[0] + size.dimensions(:inches)[1] ) * 2 * frame.price_per_inch)) * quantity
	end
	
	def refresh
	  Dir.new( directory).entries.each do |file|
	    File.new(file).rm
	  end
	end
	
	def self.repository
	  File.join(RAILS_ROOT,'orders')
	end

  def directory
    dirname = self.class.repository
    Dir.mkdir(dirname) unless File.exist?(dirname)
    dirname = File.join(RAILS_ROOT,'orders',id.to_s)
    Dir.mkdir(dirname) unless File.exist?(dirname)
    dirname
  end
    
  def ready
    !size_id.blank? and !frame_id.blank?
  end
  
  def intact
    parts = [photo.path,frame.image]
    parts.collect{|f| File.exist?(f)}.uniq == [true]
  end

  def status
    order_status.name
  end
  
  def self.all_paid
    self.find(:all,:conditions=>{:order_status_id=>OrderStatus.paid.id})
  end

  def title
    [(frame.name || "na"), (size.nil? ? "na" : size.title(:inches))].join( " / ")
  end

  def set_status
    if !frame_id.blank? and !size_id.blank? and order_status_id!=OrderStatus.deleted.id and order_status_id!=OrderStatus.paid.id 
      self.order_status = OrderStatus.unpaid
    end
  end
  
  def info_sheet
    info = %{
      <html>
        <head>
        <title></title>
        <style>
        body{font-family:Arial}
        </style>
        </head>
        <body>
        <h1>Order # #{id}</h1>
        <h2>Frame: #{frame.name}</h2>
        <h2>Size: #{size.title}</h2>
        <h2>Orientation: #{rotation==0 ? "normal" : "rotated"}</h2>
        <img src='#{self.class.preview_filename}'><br/>
        <img src='barcode.png'>
        </body>
      </html>
    }
    filename = File.join(directory,self.class.info_sheet_name)
    unless File.exist?(filename)
      open(filename, "wb") do |data|
        data.write(info)
      end 
    end
    filename
  end
  
  def components
    [info_sheet, internal_preview, photo.path, barcode, final_version]
  end
  
  def get_barcode_image
    string_to_encode = id.to_s
    if string_to_encode.nil?
      string_to_encode = "No string specified"
    end
    eps_barcode = get_barcode_eps(string_to_encode)
    return convert_eps_to_png(eps_barcode)
  end

  def get_barcode_eps(string_to_encode)
    bc = Gbarcode.barcode_create(string_to_encode)
    Gbarcode.barcode_encode(bc, Gbarcode::BARCODE_128)
    read_pipe, write_pipe  = IO.pipe
    Gbarcode.barcode_print(bc, write_pipe, Gbarcode::BARCODE_OUT_EPS)
    write_pipe.close() 
    eps_barcode = read_pipe.read()
    read_pipe.close()
    return eps_barcode
  end
  
  def convert_eps_to_png(eps_image)
    im = Magick::Image::read_inline(Base64.b64encode(eps_image)).first
    im.format = "PNG"
    im.write(File.join(directory,'barcode.png'))
    read_pipe, write_pipe = IO.pipe
    im.write(write_pipe)
     write_pipe.close() 
     png_image= read_pipe.read()
    read_pipe.close()
    return im
  end
  
  def internal_preview
    filename = File.join(directory,self.class.preview_filename)
    unless File.exist?(filename)
      thumbnail
    end
    filename
  end

  def final_version
    filename = File.join(directory,self.class.final_filename)
    unless File.exist?(filename)
      print_ready
    end
    filename
  end
  
  def barcode
    filename = File.join(directory,'barcode.png')
    unless File.exist?(filename)
      get_barcode_image
    end
    filename
  end
  
  def barcode_url
    '/barcode/order/'+id.to_s+'/barcode.png'
  end
  
  def thumbnail
    dpi_scale = (self.class.preview_size.to_f * height / width) / (DISPLAY_DPI*1.5)
    frame.render_onto(draw(:after_wrap=>true),dpi_scale).resize_to_fit(self.class.preview_size,self.class.preview_size).write(File.join(directory,self.class.preview_filename))
  end

  def print_ready
    draw(:guides=>true).write(File.join(directory,self.class.final_filename))
  end
  
  def preview
    internal_preview
  end

  def preview_url
   File.join('previews',id.to_s, self.class.preview_filename)
  end

  def stretcher
    frame.x_stretcher
  end

  def final_dimensions
    final_dimensions = size.dimensions(:inches).collect{|d| (d + (stretcher*2)) * PRINTER_DPI }
    final_dimensions.reverse! if [90,270].include?(rotation)
    final_dimensions
  end
  
  def draw(options={:after_wrap=>false, :guides=>false})
    scale = [final_dimensions[0]/photo.width, final_dimensions[1]/photo.height].max
    crop_x = x_offset * photo.width * scale
    crop_y = y_offset * photo.height * scale
    output = photo.magick.scale(scale).crop(-crop_x, -crop_y,final_dimensions[0],final_dimensions[1],true)
    if options[:guides] == true
      guidelines = Magick::Draw.new
      guidelines.stroke_dasharray(10,10)
      guidelines.stroke('#f00')
      guidelines.fill('transparent')
      guidelines.rectangle(stretcher*PRINTER_DPI,stretcher*PRINTER_DPI, final_dimensions[0]-(stretcher*PRINTER_DPI), final_dimensions[1]-(stretcher*PRINTER_DPI))
      guidelines.draw(output)
    end
    if options[:after_wrap]
      output.crop!(stretcher*PRINTER_DPI,stretcher*PRINTER_DPI, final_dimensions[0]-(stretcher*PRINTER_DPI*2), final_dimensions[1]-(stretcher*PRINTER_DPI*2),true)
    end
    output
  end
  
  def height
    final_dimensions[1]
  end
  
  def width
    final_dimensions[1]
  end
  
  def due_date
    created_at + 3.days
  end
  
  def destroy_and_delete
    if Dir.exist?(directory)
      Dir.foreach(directory) do |f|
        filename = File.join(directory,f)
        File.rm(filename)
      end
    end
    sugar_order.destroy
    photo.destroy
    #photo.destroy_and_delete if false
    destroy
  end

  def consistency_check
    derive_sugar_clone if (sugar_order_id.blank? and ready and !customer_id.blank?)
    self.sugar_order.ensure_consistency unless self.sugar_order.blank?
  end
  
  def estimated_framing(units=:inches)
    size.length(units) * (1+self.class.waste)
  end
  
  def estimated_canvas(sq_units=:inches)
    # we create an array like [1,x_dimension,y_dimension] so we can use the inject method and we start with 1 (the multiplicative identitiy)
    [1,size.dimensions(sq_units)].flatten.inject {|prod, n| ((n+frame.x_stretcher*2)*(1+self.class.waste))*prod } 
  end
  
  def derive_sugar_clone
    sugar_order = SugarOrder.clone(self)
    update_attribute(:sugar_order_id, sugar_order.id)
  end
  
end