class BatchesController < ApplicationController
  
  before_filter :login_required, :admin_required
  layout "admin"
  
  def index
    @batches = Batch.find(:all)
  end
  
  def new
    if Order.all_paid.blank?
      flash[:notice] = "There aren't any new orders to process"
    else
      send_file Batch.bundle_unbundled.path
    end
  end
  
  def show
    @batch = Batch.find(params[:id])
  end
  
  def download
    @batch = Batch.find(params[:id])
    if !@batch.path.nil? and File.exist?(@batch.path)
      send_file @batch.path
    else
      flash[:warning] = "The source file for this batch could not be located."
      redirect_to :back
    end
  end
  
end
