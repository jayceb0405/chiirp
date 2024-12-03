# config/initializers/core_exts.rb
Dir[Rails.root.join('lib/core_ext/*.rb').to_s].each { |l| require l }

module Chronic
  def self.time_class
    ::Time.zone
  end
end
