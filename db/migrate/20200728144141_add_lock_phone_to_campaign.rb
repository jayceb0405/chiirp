class AddLockPhoneToCampaign < ActiveRecord::Migration[5.2]
  def up
		add_column     :campaigns,         :lock_phone,        :boolean,           null: false,        default: false
  end

  def down
  	remove_column  :campaigns,         :lock_phone
  end
end
