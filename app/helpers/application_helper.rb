# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  
  def page_title
    "Framebuilder.com"
  end
  
  def png_fix
    %{
      <!--[if IE 6]>
      #{stylesheet_link_tag 'png_fix.css' }
      <![endif]-->
    }
  end
  
  def logo
    markaby{
      unless (controller.controller_name == "orders" and controller.action_name == "new")
        a(:href=>(home_path), :class=>"home"){
          div.logo{ 
            span "Framebuilder" 
          }
        }
      else
      div.logo{ 
        span "Framebuilder" 
        }
      end
    }
  end
  
  def all_stylesheets
  end
  
  def page_specific_stylesheets
    sheets = ["layout","style","forms"].collect{|s|  File.join(controller.controller_name,s)}
    if RAILS_ENV == "development"
      stylesheet_directory = File.dirname(File.join(RAILS_ROOT,"public",stylesheet_path(sheets[0]).gsub(/\?[0-9]+/,"")))
      Dir.mkdir(stylesheet_directory) unless File.exist?(stylesheet_directory)
      sheets.each{ |s|  File.new(File.join(RAILS_ROOT,"public",stylesheet_path(s).gsub(/\?[0-9]+/,"")),"wb")}
    end
    stylesheet_link_tag(*sheets)
  end
  
  def page_params
    {:class=>("c_#{controller.controller_name} a_#{controller.action_name} l_#{logged_in? ? "logged_in" : "logged_out"}"), :id=>("#{controller.controller_name}_#{controller.action_name}")}
  end
  
  def user_info
    if logged_in?
      user = self.current_user
      content_tag(:div, ("logged in as <span class='username'>#{user.login}</span> | " + (link_to("logout", logout_url, :class=>"logout"))),:class=>"user_info")
    end
  end

  def user_home
    if logged_in?
      if customer?
        account_path
      elsif admin?
        admin_path
      else
        home_path
      end
    else
      home_path
    end
  end

  def markaby(&block)
    Markaby::Builder.set(:indent, 1)
    Markaby::Builder.new({}, self, &block)
  end

  def doctype
    %{<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
   "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">}
  end

  def flicker_flop
    %{
      <script type="text/javascript">try {
      document.execCommand("BackgroundImageCache", false, true);
      } catch(err) {}
      </script>
    }
  end
  
  def messages
    markaby{
      div.notice{flash[:notice]} unless flash[:notice].blank?
      div.warning{flash[:warning]} unless flash[:warning].blank?
    }
  end
  
  def main_nav
    links = [
      {:title=>"Create", :controller=>"orders", :action=>"new" },
      {:title=>"HowTo", :controller=>"pages"},
      {:title=>"FAQ", :controller=>"pages"},
      {:title=>"Contact", :controller=>"pages"}
    ]
    links.collect{|l| link_to_unless_current(l[:title], {:controller=>l[:controller], :action=>(l[:action]||=nil), :id=>(l[:controller] == "pages" ? l[:title].downcase : nil)}, :id=>l[:title].underscore){|n| content_tag :span, n, :id=>n.underscore}}
  end
  
  def cart_link
  end
  
  def sign_in
  end
  
  def admin?
    logged_in? and self.current_user.admin
  end
  
  def customer?
     logged_in? and !self.current_user.admin
  end
  
  def cart_nav
    if logged_in?
      cart_size = self.current_user.customer.nil? ?   0 : self.current_user.customer.cart.size
    else
      cart_size = 0
    end
    (link_to "Cart (#{cart_size})", {:controller=>"customers", :action=>"cart"})
    if customer?
      links= [(link_to "Cart (#{cart_size})", {:controller=>"customers", :action=>"cart"})]
      links << (link_to "Sign Out", logout_path, :id=>'sign_in')
    else
      links = [(content_tag :span, "Cart (#{cart_size})")]
      links << (link_to "Sign In", {:controller=>"customers", :action=>"login"}, :id=>'sign_in')
    end
    links.join("")
  end
  
  def footer_nav
    [
      (link_to "Privacy", :controller=>"pages", :id=>"privacy"),
      (link_to "About Us", :controller=>"pages", :id=>"about_us"),
      (link_to "Legal", :controller=>"pages", :id=>"legal"),
      (link_to "Terms and Conditions", :controller=>"pages", :id=>"legal"),
    ]  
  end
  
  def js_value(object,property)
    %{
      <input type=hidden name=#{object.class.name}[#{property}] value=#{object.attribute[property]}/>
      }
  end
  
  def js_set_versions(photo)
    %{
      <script type="text/javascript">
        var dpi = #{DISPLAY_DPI}
        var side_width =#{SIDE_WIDTH}
        var display_dpi = #{DISPLAY_DPI}
        var frame_format = "#{Frame.output_format}"
        var colors= #{photo.colormap.to_json}
        var versions = #{photo.versions.collect{|k,v| {:name=>v[:name],:id=>v[:id],:url=>v[:path], :width=>v[:width], :height=>v[:height], :frame_dimensions=>v[:frame_dimensions], :pixel_dimensions=>v[:pixel_dimensions]} }.to_json}
        var  sizes=#{Size.find(:all).collect{|s| {:id=>s.id, :dimensions=>s.dimensions(:px)} }.to_json}
        var frames=#{Frame.find(:all).collect{|f| {:id=>f.id, :canvas=>f.canvas ,:image_directory =>f.image_directory(true).to_s,:x_stretcher=> f.x_stretcher * DISPLAY_DPI , :y_stretcher=> f.y_stretcher * DISPLAY_DPI,:default=>f.default,  :thickness=>(f.thickness*DISPLAY_DPI).to_i, :floating=>f.floating} }.to_json}
      </script>
    }
  end
  
    def js_order_info(order)
    %{
      <script type="text/javascript">
        var order = new Object();
        order['size'] = #{session[:order].size_id.to_s}
        order['kind'] = #{session[:order].frame_id.to_s}
        order['photo'] = #{session[:order].photo.to_json}
        order['x_offset'] = #{session[:order].x_offset}
        order['y_offset'] = #{session[:order].y_offset}
        order['tmp_img'] = \"#{session[:order].photo.largest[:path]}\"
        var rotation = order['rotation'] = #{session[:order].rotation}
      </script>
    }
  end
  
  def color_map(photo)
    markaby do
    div.colors{
      photo.colormap.each {|c|
        color = "#" + c[0].to_i.to_s(16).rjust(2,"0")  +  c[1].to_i.to_s(16).rjust(2,"0")  +  c[2].to_i.to_s(16).rjust(2,"0") 
        div.color("style"=>"background:#{color}", "title"=>"rgb(#{c[0]},#{c[1]},#{c[2]})"){"&nbsp;"}
        }
    }
  end

  end
  
  def upload_scripts
     javascript_include_tag "upload/upload_init.js"
  end
  
  def farbtastic
     "\n" + (stylesheet_link_tag "farbtastic") + "\n" +(javascript_include_tag "lib/farbtastic")
  end
  
  def corners
     "\n" + (stylesheet_link_tag "farbtastic") + "\n" +(javascript_include_tag "lib/jquery.corner.js")
  end
  
  def details(obj,details)
   markaby{
     div.details{
       details.each{|d|
         div("class"=>d.to_s){ obj[d] } if obj.has_attribute? d
       }
      }
   }
  end

  def mmethods(obj, methods)
    markaby{
    div.actions{
      methods.each{|m|
      div{ link_to m.to_s, :controller=>obj.class.name.pluralize.downcase, :action=>m, :id=>obj.id }
      }
    }
   }
  end

  def trashcan(customer)
    if customer.has_trash?
      link_to(image_tag("trash_full.png"),{:controller=>:orders,:action=>:index,:scope=>'deleted'},:class=>'trash')
    else
      link_to(image_tag("trash_empty.png"),{:controller=>:orders,:action=>:index,:scope=>'deleted'},:class=>'trash')
    end
  end
  
  def customer_order(order)
    markaby do
      div.order{
        h2 order.title
        image_tag order.preview_url
        div.tools{
          self << (link_to "remove from cart", remove_url(order) , :confirm=>'Are you sure you want to remove this item? (it will be available in your trashbin for a week)' ) if order.order_status == OrderStatus.unpaid
          self << (link_to "restore", restore_url(order) ) if order.order_status == OrderStatus.deleted
        }
      }
    end
  end
  
  def display_address(person)
    markaby{
      div.address{
        div.name [person.first_name, person.last_name].join(" ")
        div.address_1{person.address_1} unless person.address_1.blank?
        div.address_2{person.address_2} unless person.address_2.blank?
        div{ "#{person.city} #{person.state}, #{person.zip}" }
      }
    }
  end
  
  def customer(c)
    markaby{
      unless c.nil?
        div.customer{
          self << display_address(c)
          div(number_to_phone(c.phone))  unless c.phone.blank?
          div(self << (mail_to c.email)) unless c.email.blank?
        }
      else
        div "There is no customer associated with this order"
    end
    }
end

  def footer
    markaby do
    div.footer{
      div{
        footer_nav.each {|f| self << f}
        span.copyright{"&copy; #{Time.now.year} Ace Designs, Inc."}
      }
    }
    end
  end
  
  def accept_terms
    markaby do
      div.terms{
      input(:type=>"checkbox", :id=>"terms_accepted")
      label{
        self << "I have read and agree to the "
         link_to "terms & conditions.", :controller=>"pages", :id=>"legal"
      }
    }
    end
  end
  
  def tooltip(text)
    markaby{
      div.tooltip{
        div.trigger "(?)"
        div.tip{
          self << text
        }
      }
    }
  end

  def string_path(string)
    string
  end
  
  def text_img(text)
    img = "graphics/text/"+text+".jpeg"
    image_tag(img)
  end

end