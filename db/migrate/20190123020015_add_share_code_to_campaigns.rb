class AddShareCodeToCampaigns < ActiveRecord::Migration[5.2]
  def up
  	add_column :contacts, :last_contacted, :datetime
		add_column :campaigns, :share_code, :string, default: ""
		add_index :campaigns, :share_code
		add_index :users, :ios_registration

		Campaign.all.each do |c|
			c.share_code = random_code(20) until Campaign.find_by_share_code(c.share_code).nil?
			c.save
		end
  end

  def down
  	remove_column :campaigns, :share_code
  	remove_index :users, :ios_registration
  	remove_column :contacts, :last_contacted
  end

  def random_code(len = 6)
		chars = ['0'..'9', 'A'..'Z', 'a'..'z'].map { |range| range.to_a }.flatten
		len.times.map{ chars.sample }.join
	end
end
