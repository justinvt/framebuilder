class PagesController < ApplicationController
  
  layout "static"
  
  def index
    params[:page] = "home" if params[:page].blank?
    @page = File.join(Page.directory, params[:id].to_s)
    Page.allowed_extensions.each do |ext|
        with_this_extension = @page + ext
        if File.exist?( with_this_extension )
          render :file=> with_this_extension, :layout=>"static"
          return
        end
      end
    @page=Page.missing
    render :file=> @page, :layout=>"static", :status=>404
  end
  
end
