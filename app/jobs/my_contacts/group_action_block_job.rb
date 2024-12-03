# frozen_string_literal: true

# app/jobs/my_contacts/group_action_block_job.rb
module MyContacts
  class GroupActionBlockJob < ApplicationJob
    # break down a group action into smaller blocks
    # MyContacts::GroupActionBlockJob.set(wait_until: 1.day.from_now).perform_later()
    # MyContacts::GroupActionBlockJob.set(wait_until: 1.day.from_now, priority: 0).perform_later(
    def initialize(**args)
      super

      @process          = (args.dig(:process).presence || 'my_contacts_group_action_block').to_s
      @reschedule_secs  = 0
    end

    # perform the ActiveJob
    #   user_id:             Integer,
    #   triggeraction_id:    Integer,
    #   contact_campaign_id: Integer,
    #   process:             String,
    #   group_process:       Integer,
    #   group_uuid:          SecureRandom.uuid,
    #   data:                Hash
    # )
    #   (req) data:, action:            (String)
    #   (req) data:, contacts:          (Array)
    #   (req) user_id:                  (Integer)
    #
    #   (opt) run_at:                   (DateTime / default: Time.current)
    def perform(**args)
      super
      Rails.logger.info "args: #{args.inspect} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"

      args = args.deep_symbolize_keys

      return unless args.dig(:data, :contacts).present? && args[:data][:contacts].is_a?(Array)
      return unless args.dig(:user_id).to_i.positive? && (user = User.find_by(id: args[:user_id]))
      return if args.dig(:data, :action).blank?

      user_action_quantity     = args.dig(:data, :common_args, :quantity).to_i
      user_action_quantity_all = (args.dig(:data, :common_args, :quantity_all).nil? ? true : args[:data][:common_args][:quantity_all]).to_bool
      group_size               = user_action_quantity_all || user_action_quantity.zero? ? args.dig(:data, :contacts).length : user_action_quantity
      args[:file_attachments]  = args.dig(:data, :file_attachments) ? args[:data][:file_attachments].collect(&:symbolize_keys) : []

      return if group_size.zero?

      max_block_qty    = 50
      text_delay       = user.client.text_delay.to_i
      block_start_time = args.dig(:run_at).respond_to?(:strftime) ? args[:run_at] : Time.current

      args[:data][:contacts].in_groups_of(group_size, false).each do |contacts_block|
        acceptable_block_start_time = AcceptableTime.new(group_action_common_args(args.merge(client: user.client))).new_time(block_start_time)
        JsonLog.info 'MyContacts::GroupActionBlockJob.group_action_block', { acceptable_block_start_time: }, client_id: user.client_id, user_id: user.id
        Rails.logger.info "acceptable_block_start_time: #{acceptable_block_start_time.inspect} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"

        next if acceptable_block_start_time.blank?

        run_at = block_start_time = acceptable_block_start_time

        contacts_block.in_groups_of(max_block_qty, false) do |contacts|
          MyContacts::GroupActionJob.perform_later(
            user_id:             user.id,
            triggeraction_id:    args.dig(:triggeraction_id),
            contact_campaign_id: args.dig(:contact_campaign_id),
            process:             "group_#{args[:data][:action]}",
            group_process:       args.dig(:group_process),
            group_uuid:          args.dig(:group_uuid),
            data:                args.dig(:data).merge(contacts:),
            run_at:
          )

          run_at += case args[:data][:action]
                    when 'send_rvm', 'start_campaign'
                      (text_delay * [max_block_qty, contacts.length].min).seconds
                    when 'send_text'
                      ((text_delay * [max_block_qty, contacts.length].min) / [args.dig(:data, :from_phones)&.length || 0, 1].max).seconds
                    when 'contact_delete'
                      1.minute
                    else
                      30.seconds
                    end
        end

        block_start_time += args.dig(:data, :common_args, :quantity_interval).to_i.send((args.dig(:data, :common_args, :quantity_period) || 'days').to_s)
      end

      # if User is an Admin & the Client that the first Contact belongs to is active
      # the Client may not be active after the Client is deactivated by a SuperAdmin
      return unless user.admin? && Contact.find_by(id: args[:data][:contacts].first)&.client&.active?

      # add new message to div
      group_actions_count = DelayedJob.scheduled_actions(user.id, Time.current.beginning_of_month, Time.current.end_of_month + 12.months).count
      UserCable.new.broadcast user.client, user, { id: "mycontacts_group_action_count_#{user.id}", append: 'false', scrollup: 'false', html: group_actions_count.to_s }
    end

    private

    def group_action_common_args(args = {})
      JsonLog.info 'MyContacts::GroupActionBlockJob.group_action_common_args', { args: }, client_id: args.dig(:client)&.id
      {
        time_zone:     args.dig(:client)&.time_zone,
        reverse:       false,
        delay_months:  0,
        delay_days:    0,
        delay_hours:   0,
        delay_minutes: 0,
        safe_start:    (args.dig(:data, :common_args, :safe_start) || 480).to_i,
        safe_end:      (args.dig(:data, :common_args, :safe_end)   || 1200).to_i,
        safe_sun:      args.dig(:data, :common_args).to_h.fetch(:safe_sun, true),
        safe_mon:      args.dig(:data, :common_args).to_h.fetch(:safe_mon, true),
        safe_tue:      args.dig(:data, :common_args).to_h.fetch(:safe_tue, true),
        safe_wed:      args.dig(:data, :common_args).to_h.fetch(:safe_wed, true),
        safe_thu:      args.dig(:data, :common_args).to_h.fetch(:safe_thu, true),
        safe_fri:      args.dig(:data, :common_args).to_h.fetch(:safe_fri, true),
        safe_sat:      args.dig(:data, :common_args).to_h.fetch(:safe_sat, true),
        holidays:      if args.dig(:data, :common_args).to_h.fetch(:honor_holidays, true).to_bool
                         args.dig(:client)&.holidays.to_h { |h| [h.occurs_at, (h.action == 'before' ? 'after' : h.action)] }
                       else
                         {}
                       end,
        ok2skip:       false
      }
    end
    # sample group_action_common_args
    # {
    #   time_zone:     user.client.time_zone,
    #   reverse:       false,
    #   delay_months:  0,
    #   delay_days:    0,
    #   delay_hours:   0,
    #   delay_minutes: 0,
    #   safe_start:    480,
    #   safe_end:      1200,
    #   safe_sun:      true,
    #   safe_mon:      true,
    #   safe_tue:      true,
    #   safe_wed:      true,
    #   safe_thu:      true,
    #   safe_fri:      true,
    #   safe_sat:      true,
    #   holidays:      user.client.holidays&.to_h { |h| [h.occurs_at, (h.action == 'before' ? 'after' : h.action)] },
    #   ok2skip:       false
    # }
  end
end
