class AddDeadlineToTasks < ActiveRecord::Migration[5.2]
	def up
		add_column     :tasks,             :deadline,          :datetime

		add_index      :contact_api_integrations,    :data,              using: :gin
	end

	def down
		remove_column    :tasks,           :deadline

		remove_index   :contact_api_integrations,    :data
	end
end
