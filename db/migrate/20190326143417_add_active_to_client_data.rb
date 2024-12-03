class AddActiveToClientData < ActiveRecord::Migration[5.2]
  def up
    Client.all.each do |c|
      c.update(active: 1, fp_affiliate: (c.fp_affiliate ||= ""))
    end
  end

  def down
  end
end
