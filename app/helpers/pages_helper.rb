module PagesHelper
  
  def suggestions(page)
    possibile_matches = Page.suggest(params[:id])
    unless possibile_matches.blank?
      markaby{
        div.suggestions{
          h3 ("Maybe #{possibile_matches.length == 1 ? "this page" : "one of these pages"} would be helpful")
          possibile_matches.collect{|p| link_to p.titleize, :controller=>"pages", :id=>p}
        }
      }
    end
  end
  
end
