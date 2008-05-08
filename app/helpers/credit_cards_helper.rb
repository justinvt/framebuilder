module CreditCardsHelper
  
  def select_card_form(customer)
    unless customer.credit_cards.blank?
      markaby{
        form(:action=>"credit_cards/primary"){
          input(:type=>"hidden", :name=>"_method", :value=>"put")
          div.field.add{ link_to "Add a new Credit Card", new_credit_card_path }
          customer.credit_cards.each_with_index do |cc,n|
            css_class = ['credit_card','field']
            css_class << "primary" if cc.primary
            div(:class=>css_class.join(" ")){
              if cc.primary
                input(:type=>"radio", :name=>"id", :value=>n, :checked=>"checked")
              else
                 input(:type=>"radio", :name=>"id", :value=>n)
              end
                span cc.obscured_number
                link_to "(change card info)", {:controller=>:credit_cards, :action=>:edit, :id=>cc.id}
                link_to "(delete)", {:controller=>:credit_cards, :action=>:delete, :id=>n}
            }
          end
          submit_tag "Set as primary payment method", :class=>"submit"
        }
      }
    end
  end

end