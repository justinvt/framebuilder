class SugarBase < ActiveRecord::Base
  @@config = ActiveRecord::Base.configurations[RAILS_ENV]
  establish_connection(@@config.merge({'database' => "sugarcrm"}))  
  
  def self.clone
    create(:date_entered=>Time.now, :date_modified=>Time.now)
  end
  
  def consistent?
   key_map.to_a.collect{|c| self[c[0]] == c[1]}.uniq == [true]
  end
  
  def ensure_consistency
    key_map.to_a.each{|pair| update_attribute(pair[0], pair[1])}
    self
  end
  
end