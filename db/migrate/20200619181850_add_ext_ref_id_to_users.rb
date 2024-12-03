class AddExtRefIdToUsers < ActiveRecord::Migration[5.2]
  def up
		add_column     :users,             :ext_ref_id,        :string,            null: false,        default: ""
		add_index      :users,             :ext_ref_id

		add_column     :webhooks,          :data_type,         :string,            null: false,        default: ""

		Webhook.update_all( data_type: "contact" )
  end

  def down
		remove_column  :users,             :ext_ref_id
		remove_column  :webhooks,          :data_type
  end
end
