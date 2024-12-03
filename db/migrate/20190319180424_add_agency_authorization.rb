class AddAgencyAuthorization < ActiveRecord::Migration[5.2]
  def up
		add_column :users, :data, :jsonb, null: false, default: {}
    add_index  :users, :data, using: :gin
    add_column :clients, :data, :jsonb, null: false, default: {}
    add_index  :clients, :data, using: :gin

    Client.all.each do |c|
      c.card_brand      ||= c.settings && c.settings.include?(:card_brand) ? c.settings[:card_brand] : ""
      c.card_last4      ||= c.settings && c.settings.include?(:card_last4) ? c.settings[:card_last4] : ""
      c.card_exp_month  ||= c.settings && c.settings.include?(:card_exp_month) ? c.settings[:card_exp_month] : ""
      c.card_exp_year   ||= c.settings && c.settings.include?(:card_exp_year) ? c.settings[:card_exp_year] : ""
      c.client_token    ||= c.settings && c.settings.include?(:client_token) ? c.settings[:client_token] : ""
      c.card_token      ||= c.settings && c.settings.include?(:card_token) ? c.settings[:card_token] : ""

      c.pkg_max_phone_numbers     ||= c.settings && c.settings.include?(:pkg_max_phone_numbers) ? c.settings[:pkg_max_phone_numbers].to_i : 1
      c.pkg_phone_calls_allowed   ||= c.settings && c.settings.include?(:pkg_phone_calls_allowed) ? c.settings[:pkg_phone_calls_allowed].to_i : 0
      c.pkg_rvm_allowed           ||= c.settings && c.settings.include?(:pkg_rvm_allowed) ? c.settings[:pkg_rvm_allowed].to_i : 0
      c.pkg_share_funnels_allowed ||= c.settings && c.settings.include?(:pkg_share_funnels_allowed) ? c.settings[:pkg_share_funnels_allowed].to_i : 0

      c.pkg_text_message_credits  ||= c.settings && c.settings.include?(:pkg_text_message_credits) ? c.settings[:pkg_text_message_credits].to_f : 2.0
      c.pkg_text_image_credits    ||= c.settings && c.settings.include?(:pkg_text_image_credits) ? c.settings[:pkg_text_image_credits].to_f : 1.0
      c.pkg_phone_call_credits    ||= c.settings && c.settings.include?(:pkg_phone_call_credits) ? c.settings[:pkg_phone_call_credits].to_f : 2.0
      c.pkg_rvm_credits           ||= c.settings && c.settings.include?(:pkg_rvm_credits) ? c.settings[:pkg_rvm_credits].to_f : 4.0

      c.pkg_current       ||= c.settings && c.settings.include?(:pkg_current) ? c.settings[:pkg_current] : 0
      c.pkg_credit_charge ||= c.settings && c.settings.include?(:pkg_credit_charge) ? [ c.settings[:pkg_credit_charge].to_f, 0.02 ].max : 0.04
      c.pkg_mo_charge     ||= c.settings && c.settings.include?(:pkg_mo_charge) ? c.settings[:pkg_mo_charge].to_f : 0.0
      c.pkg_mo_credits    ||= c.settings && c.settings.include?(:pkg_mo_credits) ? c.settings[:pkg_mo_credits].to_i : 0

      c.unlimited       ||= c.settings && c.settings.include?(:unlimited) ? c.settings[:unlimited].to_i : 0
      c.auto_recharge   ||= 1 # changing everyone to auto_recharge
      c.auto_min_amount ||= c.settings && c.settings.include?(:auto_min_amount) ? [ c.settings[:auto_min_amount].to_i, ( 5.0 / c.pkg_credit_charge ).to_i ].max : ( 5.0 / c.pkg_credit_charge ).to_i   # changing everyone to minimum $5.00
      c.auto_add_amount ||= c.settings && c.settings.include?(:auto_add_amount) ? [ c.settings[:auto_add_amount].to_i, ( 25.0 / c.pkg_credit_charge ).to_i ].max : ( 25.0 / c.pkg_credit_charge ).to_i # changing everyone to minimum $25.00

      c.scheduleonce_booking_scheduled   ||= c.settings && c.settings.include?(:scheduleonce_booking_scheduled) ? c.settings[:scheduleonce_booking_scheduled].to_i : 0
      c.scheduleonce_booking_no_show     ||= c.settings && c.settings.include?(:scheduleonce_booking_no_show) ? c.settings[:scheduleonce_booking_no_show].to_i : 0
      c.scheduleonce_booking_canceled_reschedule_requested ||= c.settings && c.settings.include?(:scheduleonce_booking_canceled_reschedule_requested) ? c.settings[:scheduleonce_booking_canceled_reschedule_requested].to_i : 0
      c.scheduleonce_booking_rescheduled ||= c.settings && c.settings.include?(:scheduleonce_booking_rescheduled) ? c.settings[:scheduleonce_booking_rescheduled].to_i : 0
      c.scheduleonce_booking_canceled    ||= c.settings && c.settings.include?(:scheduleonce_booking_canceled) ? c.settings[:scheduleonce_booking_canceled].to_i : 0
      c.scheduleonce_booking_canceled_then_rescheduled     ||= c.settings && c.settings.include?(:scheduleonce_booking_canceled_then_rescheduled) ? c.settings[:scheduleonce_booking_canceled_then_rescheduled].to_i : 0
      c.scheduleonce_booking_completed   ||= c.settings && c.settings.include?(:scheduleonce_booking_completed) ? c.settings[:scheduleonce_booking_completed].to_i : 0

      c.sendgrid_api_key ||= c.settings && c.settings.include?(:sendgrid_api_key) ? c.settings[:sendgrid_api_key] : ""
      c.agency_access      = 0
      c.my_agencies        = []

      c.save
    end

    Package.all.each do |p|
      p.max_phone_numbers      = p.max_phone_numbers.to_i
      p.phone_calls_allowed    = p.phone_calls_allowed.to_i
      p.rvm_allowed            = p.rvm_allowed.to_i
      p.share_funnels_allowed  = p.share_funnels_allowed.to_i

      p.text_message_credits   = p.text_message_credits.to_f
      p.text_image_credits     = p.text_image_credits.to_f
      p.phone_call_credits     = p.phone_call_credits.to_f
      p.rvm_credits            = p.rvm_credits.to_f

      p.credit_charge          = p.credit_charge.to_f
      p.mo_charge              = p.mo_charge.to_f
      p.mo_credits             = p.mo_credits.to_f

      p.save
    end

    chiirp_client_id = 5
    client  = Client.find(chiirp_client_id)
    clients = Client.where.not(id: chiirp_client_id)
    client.update(agency_access: 1)

    clients.each do |c|
      c.update(my_agencies: [chiirp_client_id])
    end

    User.all.each do |u|
      u.agency_user_token = ""
      u.save
    end

    change_column :clients, :name, :string, null: false, default: ""
    change_column :clients, :address1, :string, null: false, default: ""
    change_column :clients, :address2, :string, null: false, default: ""
    change_column :clients, :city, :string, null: false, default: ""
    change_column :clients, :state, :string, null: false, default: ""
    change_column :clients, :zip, :string, null: false, default: ""
    change_column :clients, :phone, :string, null: false, default: ""
    change_column :clients, :time_zone, :string, null: false, default: "UTC"
    change_column :clients, :next_pmt_date, :date, null: false, default: -> { "NOW()" }

    # change all User.access_level from 8 to 5
    User.where(access_level: 8).update_all(access_level: 5)
  end

  def down
  	# change all User.access_level from 5 to 8
    remove_column :clients, :data
  	remove_column :users, :data
  	User.where(access_level: 5).update_all(access_level: 8)
  end
end
