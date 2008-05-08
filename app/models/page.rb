require 'amatch'

class Page < ActiveRecord::Base
  
include Amatch
  
  def self.directory
    "public/pages"
  end
  
  def self.allowed_extensions
    ['.html','.rhtml']
  end
  
  def self.missing
    File.join(directory,'missing.rhtml')
  end
  
  def self.possibilities
    ["howto","faq","contact","privacy", 'legal']
  end
  
  def self.suggestion_distance
    2
  end
  
  def self.suggest(page)
     m = Sellers.new(page.downcase)
     best = possibilities.min{|a,b| m.match(a) <=> m.match(b) }
     options = possibilities.reject{|o| m.match(o) >= suggestion_distance }
     options.empty? ? [best] : options
     options
  end
  
end
