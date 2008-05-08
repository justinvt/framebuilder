module OrdersHelper
  
  def tabs
    links = [
      {:title=>"Size", :controller=>"orders", :action=>"size" },
      {:title=>"Framing", :controller=>"orders", :action=>"kind" },
      {:title=>"Finalize", :controller=>"orders", :action=>"finalize" },
    ]
    links.collect{|l| link_to_unless_current(l[:title], {:controller=>l[:controller], :action=>(l[:action]||=nil), :id=>(l[:controller] == "page" ? l[:title].downcase : nil)}, :class=>"tab"){|n| content_tag :span, n, :class=>"tab"}}
    links = [
      link_to_unless_current("Size", {:controller=>"orders", :action=>"size"},:class=>"tab"){|n| content_tag :span, n, :class=>"tab"},
      link_to_unless_current("Type", {:controller=>"orders", :action=>"kind"}, :class=>"tab"){|n| content_tag :span, n, :class=>"tab"},
      link_to_unless_current("Finalize", {:controller=>"orders", :action=>"finalize"}, :class=>"tab"){|n| content_tag :span, n, :class=>"tab"}
      ]
      links.join("")
    #links.collect{|l| content_tag :span, l[:title], :class=>"tab" }
  end
  
  def frame(f)
  	markaby do
  	  div.kind.option{
		  img("src"=>f.sample_image)
		  input("id"=>f.css_id,"type"=>"radio","name"=>"frame[frame_id]", "value"=>f.id)
		  label{
		    span.name f.name.titleize
	      }
			}
		end
  end

  def barcode(order)
    if File.exist?(order.barcode)
      image_tag(File.join("http://localhost:3000",order.barcode_url))
    end
  end
  
  def thumbnail(order)
    if File.exist?(order.internal_preview)
      image_tag(File.join("http://localhost:3000",'images',order.preview_url))
    end
  end
  
  def hidden_values
    %{  #{hidden_field :frame, :x_offset}
        #{hidden_field :frame, :y_offset}
        #{hidden_field :frame, :rotation}
        #{(hidden_field :frame, :frame_id) unless params[:action]=="kind"}
      }
  end

  
end
