class AddClientNextPmtDate < ActiveRecord::Migration[5.2]
  def up
		add_column :clients, :next_pmt_date, :date

		Client.all.each do |c|
			months_advance = 0
			months_advance = months_advance + 1 while (c.created_at + months_advance.month) < Time.current
			c.next_pmt_date = c.created_at + months_advance.month
			c.save
		end
  end

  def down
  	remove_column :clients, :next_pmt_date
  end
end
