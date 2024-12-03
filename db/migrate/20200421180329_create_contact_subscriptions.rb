class CreateContactSubscriptions < ActiveRecord::Migration[5.2]
  def up
    create_table :contact_subscriptions do |t|
			t.references :contact,           foreign_key: {on_delete: :cascade}
      t.string     :phone,             null: false,        default: "",        index: true
      t.datetime   :ended_at,                                                  index: true

      t.timestamps
    end

    add_index      :contact_subscriptions,  :created_at

    rename_column  :twmessages,        :price,             :cost

    add_column     :twmessages,        :msg_type,          :string,            null: false,        default: "",        index: true
    add_column     :twmessages,        :subscription,      :boolean,           null: false,        default: false

    ActiveRecord::Base.record_timestamps = false

    Twmessage.where( status: "voicemail" ).update_all( msg_type: "voicemail" )
    Twmessage.where( status: "voicecallin" ).update_all( msg_type: "voicein" )
    Twmessage.where( status: "voicecallout" ).update_all( msg_type: "voiceout" )
    Twmessage.where( account_sid: Rails.application.credentials[Rails.env.to_sym][:slybroadcast][:uid] ).update_all( msg_type: "rvmout" )
    Twmessage.where( msg_type: "" ).joins(:contact).where( "twmessages.from_phone = contacts.phone" ).update_all( msg_type: "textin" )
    Twmessage.where( msg_type: "" ).joins(:contact).where( "twmessages.to_phone = contacts.phone" ).update_all( msg_type: "textout" )
    Twmessage.where( msg_type: "" ).where( "message ILIKE 'email: %'" ).update_all( msg_type: "emailout" )
    Twmessage.where( msg_type: "" ).where( to_phone: Twnumber.pluck(:phonenumber) ).update_all( msg_type: "textoutuser" )
    Twmessage.where( msg_type: "" ).where( from_phone: Twnumber.pluck(:phonenumber) ).update_all( msg_type: "textinuser" )
    Twmessage.where( msg_type: "" ).where( to_phone: User.pluck(:phone) ).update_all( msg_type: "textoutuser" )

    ActiveRecord::Base.record_timestamps = true
  end

  def down
  	drop_table     :contact_subscriptions

    rename_column  :twmessages,        :cost,              :price

    remove_column  :twmessages,        :msg_type
    remove_column  :twmessages,        :subscription
  end
end
