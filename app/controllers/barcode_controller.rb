require 'RMagick'

class BarcodeController < ApplicationController

  def send_barcode
    @order = Order.find(params[:id])
    @order.barcode
    headers["Content-Type"] = "image/png"
    render :text=> Magick::ImageList.new(@order.barcode).first.to_blob{self.format="PNG"}
  end

end