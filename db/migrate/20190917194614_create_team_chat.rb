class CreateTeamChat < ActiveRecord::Migration[5.2]
	def up
		create_table :user_chats do |t|
			t.references :from_user,         references: :users, index: true,        foreign_key: {to_table: :users, on_delete: :cascade}
			t.references :to_user,           references: :users, index: true,        foreign_key: {to_table: :users, on_delete: :cascade}
			t.references :contacts,          default: 0,         index: true
			t.text       :content,           default: "",        null: false
			t.integer    :automated,         default: 0,         null: false
			t.datetime   :read_at

			t.timestamps
		end

		rename_table   :push_users,        :user_pushes

		add_column     :user_pushes,        :target,            :string,            default: "",         null: false
		add_column     :user_pushes,        :data,              :jsonb,             default: {},         null: false

		UserPush.all.each do |user_push|
			user_push.update( target: "mobile", mobile_key: user_push.player_id )
		end
	end

	def down
		drop_table :user_chats
	end
end
