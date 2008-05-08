module CustomersHelper
  
  def order(o)
    markaby{
      div.order{
        div.size{
          h2 o.size.title
        }
        div.frame{
          h2 o.frame.title
        }
        div.price{
          span.dollar_amount o.price
        }
      }
    }
  end
  
  def orders(ords)
    total = ords.collect{|o|o.price}.sum
    markaby{
      div.orders{
        ords.each{|o| self << order(o) }
      }
      div.total{ 
        h2 "Total"
        span.dollar_ammount total 
        }
    }
  end
  
  def order_form(orders)
    #orders = (orders * 8).flatten
    zip = self.current_user.customer.zip
    total = orders.collect{|o|o.price}.sum
    shipping_weight = orders.collect{|o| o.size.weight}.sum
    shipping_distance = self.current_user.customer.distance || 0
    shipping_and_handling = shipping_weight * shipping_distance
    markaby{
      form("action"=>'/pay', "method"=>"post"){
        orders.each do |o|
        div.order{
          div.tools{
            self << (link_to "remove from cart", remove_url(o) , :confirm=>'Are you sure you want to remove this item? (it will be available in your trashbin for a week)' )
          }
          unless request.env['SERVER_NAME'] == "localhost"
            self << (link_to image_tag(o.preview_url),url_for(:controller=>'orders',:action=>"load_by_id",:id=>o.id), :class=>"preview") unless o.photo.blank?

          end
             div.field{
            input.quantity("name"=>"orders[#{o.id}][quantity]", "value"=>o.quantity)
            label{
              a(:href=>url_for(:controller=>'orders',:action=>"load_by_id",:id=>o.id)){
                span.size o.size.title
                span " / "
                span.frame o.frame.name
              }
            }
          }
          div.price{
            number_to_currency(o.price)
          }
          br.cleaner
        }
        end
        div.sub_total{ 
          h2 "Sub Total"
          span.dollar_amount number_to_currency(total)
        }
        div.sub_total.shipping_and_handling{
          if zip.blank?
            h2 "Shipping & Handling"
              h3.distance{
               self << "Distance"
               span.value "(unknown)"
             }
            h3.weight{
              self << "Weight"
              span.value shipping_weight
              self << " lbs."
            }
            span.dollar_amount "We can't calculate this yet without a zip in your billing address."
            div.ajax_form{
              input.zip!(:type=>"text", :name=>"zip", :value=>"zip")
              input.zip_submit(:type=>"button", :value=>'calculate')
            }
          else
            h2 "Shipping & Handling"
            h3.distance{
               self << "Distance"
               span.value shipping_distance
               self << " mi."
             }
            h3.weight{
              self << "Weight"
              span.value - shipping_weight
              self << " lbs."
            }
            span.dollar_amount number_to_currency(shipping_and_handling)
          end
        }
        div.total{
          h2 "Total"
          span.dollar_amount number_to_currency(total + shipping_and_handling)
        }
        input(:type=>"submit", :value=>"checkout", :class=>"submit")
      }
    }
  end

  
end
