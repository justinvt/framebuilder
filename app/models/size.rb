class Size < ActiveRecord::Base
  
  def dpi
    DISPLAY_DPI
  end
  
  def unit_multiplier
    {
      :inches=>1,
      :yards =>1/36,
      :cm=>2.54,
      :m =>0.0254,
      :px=>dpi
    }
  end
  
  def unit_title
    {
      :inches=>"\"",
      :yards =>" yd",
      :cm=>"cm",
      :m =>"m",
      :px=>"px"
    }
  end
  
  def self.default
    self.find(:first)
  end
  
  def dimensions(unit=:inches)
    [width,height].collect do |d|
      dim = d*(unit_multiplier[unit.to_sym]/unit_multiplier[units.to_sym])
      unit.to_sym==:px ? dim.to_i : dim.to_f.round(2)
    end
  end
  
  def self.max_dimension
    find(:all).collect{|s| s.dimensions(:px) }.flatten.max
  end
  
  def minimum_dpi
    144
  end
  
  def length(unit=:inches)
    (dimensions(unit)[0] + dimensions(unit)[1])*2
  end
  
  def title(unit=units)
     dimensions(unit.to_s).collect{|d| d.to_s  + unit_title[unit.to_sym]}.join(" x ")
  end
  
  def suitable_for?(image_width, image_height)
    resolutions = [image_width.to_f / width, image_height.to_f / height]
    resolutions.collect{ |r| r >= minimum_dpi }  == [true,true]
  end
  
  def minimum_image_size
     dimensions.collect{ |r| r*minimum_dpi }
  end
  
  def area
    dimensions("px")[0] * dimensions("px")[1]
  end
  
  def css_id
    "size_" + id.to_s
  end
  
  def self.find_by_dimensions(dims)
    self.find(:all).select{|s| s.dimensions.to_json == dims}[0]
  end

end
