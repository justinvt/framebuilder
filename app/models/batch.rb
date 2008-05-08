class Batch < ActiveRecord::Base
  
  require 'zip/zip'
  require 'zip/zipfilesystem'
  require 'RMagick'

  has_many :orders
  
  def name
    [self.class.name.downcase,id.to_s].join("_")
  end
  
  def self.directory
    dir = File.join(RAILS_ROOT,'batches')
    Dir.mkdir(dir) unless File.exist?(dir)
    dir
  end
  
  def filename
    File.join(directory,"#{name}.zip")
  end

  def directory
    dir = File.join(self.class.directory,id.to_s)
    Dir.mkdir(dir) unless File.exist?(dir)
    dir
  end

  def order_directories
  end
  
  def to_printer
    "to_printer"
  end

  def self.bundle_unbundled
    new_batch = Batch.create
    Order.ready_for_batching.each do |o|
      o.update_attributes(:batch_id=>new_batch.id)
      #o.update_attributes(:batch_id=>new_batch.id,:order_status_id=>OrderStatus.printed.id)
    end
    new_batch.reload.bundle
    return new_batch
  end

  def bundle
    File.delete(filename) if File.file?(filename)
    Zip::ZipFile.open(filename, Zip::ZipFile::CREATE) {
     |zipfile|
     #zipfile.mkdir "abc"
     zipfile.mkdir File.join(name,to_printer)
     self.orders.each{|order|
        zipfile.add(File.join(name,to_printer,[order.id.to_s,Order.print_format].join(".")), order.final_version)
         order.components.each{|comp|
         if File.exist?(comp)
             zipfile.add(File.join(name,order.id.to_s,File.basename(comp)),comp)
          end
         }
       }
   }
   update_attributes(:path=>filename)
   return filename
  end
  
end