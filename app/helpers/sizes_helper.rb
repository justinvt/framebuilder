module SizesHelper
  
  def size(s)
    markaby{
      div.size("id"=>"size_"+s.id.to_s){
        h1.title{ link_to s.title(:inches), :controller=>"sizes", :action=>"edit", :id=>s.id }
        self << mmethods(s, [:edit, :delete])
      }
    }
  end
  
end
