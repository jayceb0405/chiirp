# frozen_string_literal: true

# To access the object and args of a job use this:
# job = Delayed::Job.last
# job.payload_object
# job.payload_object.object
# job.payload_object.method_name
# job.payload_object.args

# to update the args of a Delayed::Job
# dj = Delayed::Job.find_by(id: Integer)
# dj.payload_object.args (change the args)
# dj.handler = dj.payload_object.to_yaml
# dj.save

# To process a job right now from IRB:
# Delayed::Job.last.invoke_job

# app/models/delayed_job.rb
class DelayedJob < ApplicationRecord
  belongs_to :contact, optional: true
  belongs_to :triggeraction, optional: true
  belongs_to :user, optional: true
  belongs_to :contact_campaign, class_name: '::Contacts::Campaign', optional: true

  QUEUE_PRIORITY = {
    default:             {
      0  => { process: %w[message_attach_media] },
      5  => { process: %w[holiday_adjust_delayed_jobs] },
      10 => { process: %w[subscribe_to_message_thread] },
      20 => { process: %w[create_note destroy_expired_packages unsubscribe_from_message_thread update_contact_info] },
      30 => { process: %w[message_status_update charge_monthly_fees new_client_create new_client_endpoint_stripe_customer_created phone_number_status_update] },
      40 => { process: %w[dlc10_campaign_create dlc10_charge_for_campaigns] }
    },
    campaigns:           {
      0  => { process: %w[stop_campaign] },
      5  => { process: %w[start_campaign] },
      10 => { process: %w[start_campaigns_on_incoming_call start_campaigns_on_missed_call trigger_campaigns] },
      35 => { process: %w[broadcast_stop_campaign] }
    },
    housecallpro:        {
      15 => { process: %w[housecallpro_update_balance housecallpro_update_contact_from_customer housecallpro_update_invoice housecallpro_process_job housecallpro_tag_applied] },
      25 => { process: %w[housecallpro_import_job] },
      35 => { process: %w[housecallpro_import_customer_group housecallpro_import_estimates_block housecallpro_import_jobs_block] },
      45 => { process: %w[housecallpro_import_customers housecallpro_import_estimates housecallpro_import_jobs] }
    },
    imports:             {
      20 => { process: %w[csv_import] },
      25 => { process: %w[jobnimbus_import_contact sendjim_import_contact servicetitan_import_customers_by_customer successware_import_contact] },
      30 => { process: %w[servicetitan_import_customers_by_customer_block] },
      35 => { process: %w[jobnimbus_import_contacts_blocks sendjim_import_contacts_block servicetitan_import_customers_by_client_page successware_import_contacts_blocks] },
      45 => { process: %w[jobnimbus_import_contacts sendjim_import_contacts servicetitan_import_customers_by_client successware_import_contacts] }
    },
    jobber:              {
      15 => { process: %w[jobber_process_event] },
      25 => { process: %w[jobber_import_contact] },
      35 => { process: %w[jobber_import_contacts_blocks] },
      45 => { process: %w[jobber_import_contacts] }
    },
    integrations:        {
      5  => { process: %w[add_contact_to_five9_list remove_contact_from_five9_list send_to_salesrabbit] },
      10 => { process: %w[angi_process_actions_for_event fieldroutes_process_actions_for_event process_actions_for_webhook] },
      15 => { process: %w[angi_process_event dope_tag_applied fieldroutes_process_event five9_tag_applied jobber_tag_applied jobnimbus_tag_applied pcrichard_processes responsibid_process_event sendjim_tag_applied successware_process_event thumbtack_process_event] },
      25 => { process: %w[fieldpulse_import_contact fieldroutes_import_contact send_note] },
      35 => { process: %w[fieldpulse_import_contacts_blocks fieldroutes_import_contacts_blocks salesrabbit_client_contact_updates salesrabbit_update_contact salesrabbit_update_contacts_from_leads] },
      45 => { process: %w[fieldpulse_import_contacts fieldroutes_import_contacts] },
      65 => { process: %w[searchlight_post] },
      90 => { process: %w[google_reviews_load] }
    },
    notify:              {
      0  => { process: %w[show_active_contacts show_message_thread_message update_unread_message_indicators] },
      5  => { process: %w[toast] },
      10 => { process: %w[send_text_to_user send_task_notifications notify_admins] },
      15 => { process: %w[send_push send_push_or_text] },
      21 => { process: %w[slack_channel_create] },
      22 => { process: %w[slack_channel_invite] },
      25 => { process: %w[send_slack] },
      30 => { process: %w[process_msg_callback] }
    },
    secondary:           {
      5  => { process: %w[custom_field_action] },
      10 => { process: %w[campaign_destroy group_destroy stage_destroy tag_destroy] },
      15 => { process: %w[add_group add_stage apply_tag apply_tag_by_name assign_lead_source assign_user contact_awake contact_sleep ok2email_off ok2text_off ok2text_on package_job remove_group remove_stage remove_tag send_rvm] },
      20 => { process: %w[send_email] },
      25 => { process: %w[create_new_task contact_export] },
      30 => { process: %w[campaign_destroyed triggeraction_references_destroyed] },
      35 => { process: %w[group_add_group group_add_stage group_add_tag group_assign_lead_source group_assign_user group_contact_awake group_contact_delete group_contact_sleep group_ok2text_off group_ok2text_on group_remove_group group_remove_stage group_remove_tag group_send_email group_send_rvm group_send_text group_start_campaign group_stop_campaign] },
      40 => { process: %w[contact_delete] },
      45 => { process: %w[update_client_labels] },
      50 => { process: %w[clean_sign_in_debug_data access_token_maintenance] }
    },
    servicemonster:      {
      15 => { process: %w[servicemonster_tag_applied servicemonster_process_job servicemonster_update_contact_from_account servicemonster_update_contact_from_customer] },
      25 => { process: %w[servicemonster_import_job] },
      35 => { process: %w[servicemonster_import_accounts_group servicemonster_import_jobs_block] },
      45 => { process: %w[servicemonster_import_accounts servicemonster_import_jobs] }
    },
    servicetitan:        {
      10 => { process: %w[servicetitan_update_estimate servicetitan_update_call] },
      15 => { process: %w[servicetitan_events_process_actions servicetitan_tag_applied servicetitan_update_contact_from_job servicetitan_update_contact_webhook servicetitan_report_results_contact] },
      25 => { process: %w[servicetitan_import_job servicetitan_report_results_block] },
      35 => { process: %w[servicetitan_estimate_import_by_client_block servicetitan_import_jobs_block servicetitan_report_results_client] },
      40 => { process: %w[servicetitan_estimate_import_by_client servicetitan_import_jobs servicetitan_report_results_all_clients] }
    },
    servicetitannotes:   {
      10 => { process: %w[servicetitan_send_note] }
    },
    servicetitanupdates: {
      20 => { process: %w[servicetitan_update_contact_estimates] },
      35 => { process: %w[servicetitan_update_existing_open_jobs_by_job servicetitan_membership_events_by_contact] },
      40 => { process: %w[servicetitan_import_orphaned_estimates_by_client servicetitan_membership_events_by_client_page servicetitan_update_estimates servicetitan_update_existing_open_estimates_by_client servicetitan_update_existing_open_jobs_by_client servicetitan_update_job_balance_by_job] },
      45 => { process: %w[servicetitan_import_orphaned_estimates_all_clients servicetitan_membership_events_by_client servicetitan_update_estimate_blocks servicetitan_update_existing_open_estimates_all_clients servicetitan_update_job_balance_by_client] },
      50 => { process: %w[servicetitan_membership_events_all_clients servicetitan_update_existing_open_jobs_all_clients servicetitan_update_job_balance_all_clients] },
      90 => { process: %w[servicetitan_customers_balance_actions] },
      91 => { process: %w[servicetitan_customers_balance_by_contact] },
      92 => { process: %w[servicetitan_customers_balance_by_client_page] },
      93 => { process: %w[servicetitan_customers_balance_by_client] },
      94 => { process: %w[servicetitan_customers_balance_all_clients] }
    },
    urgent:              {
      0  => { process: %w[send_fb_message send_ggl_message send_text] },
      4  => { process: %w[broadcast_send_text] },
      5  => { process: %w[send_message_to_five9] },
      10 => { process: %w[call_contact] },
      15 => { process: %w[reschedule_job] },
      20 => { process: %w[restart_dyno] }
    },
    zapier:              {
      10 => { process: %w[zapier_receive_new_contact] },
      15 => { process: %w[zapier_receive_updated_contact] },
      20 => { process: %w[zapier_receive_remove_tag] },
      25 => { process: %w[zapier_receive_new_tag] }
    }
  }.freeze

  scope :scheduled_actions, ->(user_id, from_date, to_date) {
    groups = Hash.new { |hash, key| hash[key] = { user_id:, contacts_count: 0, min_run_at: nil, max_run_at: nil } }
    jobs = where(user_id:)
           .where(triggeraction_id: 0)
           .where(run_at: from_date..to_date)
           .where(group_process: 1)
           .where(failed_at: nil)
           .where(locked_at: nil)
    jobs = jobs.or(where(user_id:).where(triggeraction_id: 0).where(run_at: from_date..to_date).where(process: 'contact_export').where(failed_at: nil).where.not(locked_at: nil))
    jobs.find_each do |job|
      groups[job.group_uuid][:id] = job.id if groups[job.group_uuid][:id].to_i > job.id || groups[job.group_uuid][:id].to_i.zero?
      groups[job.group_uuid][:group_uuid] = job.group_uuid
      groups[job.group_uuid][:contacts_count] += job.data.dig('contacts')&.length || 1
      groups[job.group_uuid][:min_run_at] = job.run_at if groups[job.group_uuid][:min_run_at].nil?
      groups[job.group_uuid][:max_run_at] = job.run_at if groups[job.group_uuid][:max_run_at].nil? || groups[job.group_uuid][:max_run_at] < job.run_at
      groups[job.group_uuid][:locked_at] = job.locked_at
      groups[job.group_uuid][:process] = job.process.gsub(%r{^(group|broadcast)_}, '')
    end

    groups.values.sort_by { |v| v[:min_run_at] }
  }
  scope :scheduled_imports, ->(user_id) {
    where("data->>'current_user_id' = ?", user_id.to_s)
      .where(triggeraction_id: 0)
      .where(contact_id: [0, nil])
      .where(process: 'csv_import')
      .where(attempts: 0)
  }
  scope :scheduled_messages, ->(user_id, from_date, to_date) {
    joins(:contact)
      .where(contacts: { user_id: })
      .where(process: 'send_text')
      .where(triggeraction_id: 0)
      .where(group_process: 0)
      .where(group_uuid: nil)
      .where(run_at: from_date..to_date)
      .order(:run_at)
      .map { |c| { id: c.id, contact_id: c.contact.id, title: "txt: #{c.contact.fullname}", start: c.run_at } }
  }

  def self.find_nested_process(matrix, process)
    matrix.each_key do |queue|
      matrix[queue].each_key do |priority|
        return queue.to_s, priority if matrix.dig(queue, priority, :process).include?(process)
      end
    end

    ['default', 99]
  end

  # DelayedJob.job_priority(String)
  def self.job_priority(process = nil)
    self.find_nested_process(QUEUE_PRIORITY, process).last
  end

  # DelayedJob.job_queue(String)
  def self.job_queue(process = nil)
    return 'default' if %w[staging development].include?(Rails.env)

    self.find_nested_process(QUEUE_PRIORITY, process).first
  end

  # reschedule DelayedJob.run_at either by advance (days into future) or date (specific day to revise run_at)
  # delayed_job.reschedule()
  #   (opt) advance:   (Integer)
  #     ~ or ~
  #   (opt) date_time: (DateTime)
  def reschedule(args = {})
    response = { success: false, new_run_at: nil }

    if args.dig(:advance).is_a?(ActiveSupport::Duration)
      response = reschedule_run_at(self.run_at + args[:advance])
    elsif args.dig(:date_time).respond_to?(:utc)
      response = reschedule_run_at(args[:date_time])
    end

    response
  end

  private

  def after_create_commit_actions; end

  def after_destroy_commit_actions
    release_phone_number_reservation
    Contacts::Campaigns::Triggeraction.cancelled(self.contact_campaign_id, self.triggeraction_id)
  end

  def after_update_commit_actions; end

  # define common_args to define a new run_at from DelayedJob.data
  # commmon_args_from_data(start_time: Time)
  #   (req) start_time:    (Time)
  def common_args_from_data(args = {})
    return nil if (client = self.user&.client || self.contact&.client).nil? || self.data.dig('common_args').blank?

    {
      start_time:    args.dig(:start_time).is_a?(Time) ? args[:start_time] : Time.current,
      interval:      client.text_delay,
      time_zone:     client.time_zone,
      reverse:       false,
      delay_months:  self.data.dig('common_args', 'delay_months').to_i,
      delay_days:    self.data.dig('common_args', 'delay_days').to_i,
      delay_hours:   self.data.dig('common_args', 'delay_hours').to_i,
      delay_minutes: self.data.dig('common_args', 'delay_minutes').to_i,
      safe_start:    self.data.dig('common_args', 'safe_start').to_i,
      safe_end:      self.data.dig('common_args', 'safe_end').to_i,
      safe_sun:      self.data.dig('common_args', 'safe_sun').to_bool,
      safe_mon:      self.data.dig('common_args', 'safe_mon').to_bool,
      safe_tue:      self.data.dig('common_args', 'safe_tue').to_bool,
      safe_wed:      self.data.dig('common_args', 'safe_wed').to_bool,
      safe_thu:      self.data.dig('common_args', 'safe_thu').to_bool,
      safe_fri:      self.data.dig('common_args', 'safe_fri').to_bool,
      safe_sat:      self.data.dig('common_args', 'safe_sat').to_bool,
      holidays:      if self.data.dig('common_args', 'honor_holidays').to_bool
                       client.holidays.to_h { |h| [h.occurs_at, (h.action == 'before' ? 'after' : h.action)] }
                     else
                       {}
                     end,
      ok2skip:       self.data.dig('common_args', 'ok2skip').to_bool
    }
  end

  # define common_args to define a new run_at from Triggeraction
  # commmon_args_from_triggeraction(start_time: Time, triggeraction: Triggeraction)
  #   (req) start_time:    (Time)
  #   (req) triggeraction: (Triggeraction)
  def common_args_from_triggeraction(args = {})
    return nil if (client = self.user&.client || self.contact&.client).nil? || !args.dig(:triggeraction).is_a?(Triggeraction)

    {
      start_time:    args.dig(:start_time).is_a?(Time) ? args[:start_time] : Time.current,
      interval:      client.text_delay,
      time_zone:     client.time_zone,
      reverse:       Trigger::REVERSE_TYPES.include?(args[:triggeraction].trigger.trigger_type),
      delay_months:  args[:triggeraction].delay_months,
      delay_days:    args[:triggeraction].delay_days,
      delay_hours:   args[:triggeraction].delay_hours,
      delay_minutes: args[:triggeraction].delay_minutes,
      safe_start:    args[:triggeraction].safe_start,
      safe_end:      args[:triggeraction].safe_end,
      safe_sun:      args[:triggeraction].safe_sun,
      safe_mon:      args[:triggeraction].safe_mon,
      safe_tue:      args[:triggeraction].safe_tue,
      safe_wed:      args[:triggeraction].safe_wed,
      safe_thu:      args[:triggeraction].safe_thu,
      safe_fri:      args[:triggeraction].safe_fri,
      safe_sat:      args[:triggeraction].safe_sat,
      holidays:      client.holidays.to_h { |h| [h.occurs_at, (h.action == 'before' ? 'after' : h.action)] },
      ok2skip:       args[:triggeraction].ok2skip
    }
  end

  def release_phone_number_reservation
    PhoneNumberReservations.new(from_phonenumber).release(self.run_at, (self.user&.client || self.contact&.client)&.text_delay)
  end

  def reschedule_run_at(new_run_at)
    return unless new_run_at.respond_to?(:utc)

    response = { success: false, new_run_at: nil }

    case self.data.dig('action')
    when 'send_text'
      if (triggeraction = self.triggeraction).present?
        return response if (common_args = common_args_from_triggeraction(start_time: new_run_at, triggeraction:)).nil?

        new_run_at = AcceptableTime.new(common_args).new_time(common_args[:start_time].in_time_zone(common_args[:time_zone]))
        send_to    = triggeraction.send_to.present? ? triggeraction.send_to.split('_') : ['']
      elsif self.data.dig('common_args')
        return response if (common_args = common_args_from_data(start_time: new_run_at)).nil?

        new_run_at = AcceptableTime.new(common_args).new_time(common_args[:start_time].in_time_zone(common_args[:time_zone]))
        send_to    = self.process == 'broadcast_send_text' ? ['contact'] : ''
      else
        return response
      end

      from_phone = from_phonenumber
      new_run_at = PhoneNumberReservations.new(from_phone).reserve(common_args.merge(action_time: new_run_at.utc)) if common_args.present? && new_run_at.present? && %w[contact primary].include?(send_to[0])

      if new_run_at.present?
        old_run_at = self.run_at
        self.update(run_at: new_run_at.utc)
        PhoneNumberReservations.new(from_phone).release(old_run_at, common_args[:interval]) if common_args.present? && %w[contact primary].include?(send_to[0])
        response = { success: true, new_run_at: new_run_at.utc }
      end
    when 'add_group', 'add_stage', 'aiagent_start_session', 'apply_tag', 'assign_lead_source', 'call_contact', 'create_new_task', 'custom_field_action', 'ok2email_off', 'ok2text_off', 'remove_stage', 'remove_group', 'remove_tag', 'subscribe_to_message_thread', 'send_email', 'send_rvm', 'send_slack', 'start_campaign', 'stop_campaign', 'unsubscribe_from_message_thread', 'update_contact_info'

      if (triggeraction = self.triggeraction).present?
        return response if (common_args = common_args(start_time: new_run_at, triggeraction:)).nil?
      elsif self.data.dig('common_args')
        return response if (common_args = common_args_from_data(start_time: new_run_at)).nil?
      else
        return response
      end

      new_run_at = AcceptableTime.new(common_args).new_time(common_args[:start_time].in_time_zone(common_args[:time_zone])) if common_args.present?

      if new_run_at.present?
        self.update(run_at: new_run_at.utc)
        response = { success: true, new_run_at: new_run_at.utc }
      end
    end

    response
  end

  def from_phonenumber
    case self.data.dig('from_phone')
    when 'user_number'
      self.contact.user.default_from_twnumber&.phonenumber.to_s
    when 'last_number'
      self.contact.latest_client_phonenumber(default_ok: true, phone_numbers_only: true)&.phonenumber.to_s
    else
      self.data.dig('from_phone')
    end
  end
end
