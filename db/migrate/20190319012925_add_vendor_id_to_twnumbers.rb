class AddVendorIdToTwnumbers < ActiveRecord::Migration[5.2]
  def up
		add_column :twnumbers, :vendor_id, :string, null: false, default: ""

		leased_phone_numbers = SMS.new.all_leased_phone_numbers(phone_number: true, vendor_id: true)

		Twnumber.all.each do |t|
			t.update(vendor_id: leased_phone_numbers[t.phonenumber])
		end
  end

  def down
  	remove_column :twnumbers, :vendor_id
  end
end
