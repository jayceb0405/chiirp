class AddNumSegmentsToTwmessages < ActiveRecord::Migration[5.2]
  def up
  	remove_column  :twmessages,        :price
  	add_column     :twmessages,        :price,             :decimal,           default: 0,         null: false
  	add_column     :twmessages,        :num_segments,      :integer,           default: 0,         null: false
  end

  def down
  	remove_column  :twmessages,        :price
  	add_column     :twmessages,        :price,             :integer
  	remove_column  :twmessages,        :num_segments
  end
end
