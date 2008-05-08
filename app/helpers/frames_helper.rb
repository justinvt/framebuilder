module FramesHelper
  
  def frame(f)
    markaby{
      div.frame("id"=>"frame_"+f.id.to_s){
        h1.title { link_to f.name, :controller => "frames", :action => "edit", :id => f.id }
        self << details(f,[:depth])
        self << mmethods(f, [:edit, :delete])
      }
    }
  end
  

  
end
