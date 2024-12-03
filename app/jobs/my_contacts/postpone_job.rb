# frozen_string_literal: true

# app/jobs/my_contacts/postpone_job.rb
module MyContacts
  class PostponeJob < ApplicationJob
    # postpone jobs by group_uuid
    # MyContacts::PostponeJob.set(wait_until: 1.day.from_now).perform_later()
    # MyContacts::PostponeJob.set(wait_until: 1.day.from_now, priority: 0).perform_later(
    #   user_id:             Integer,
    #   group_uuid:          SecureRandom.uuid
    #   advance:             2.days
    # )
    #   (req) user_id:       (Integer)
    #   (req) group_uuid:    (String)
    #   (req) advance:       (ActiveSupport::Duration || DateTime)
    #
    def perform(**args)
      super

      user = User.find_by(id: args.dig(:user_id))
      return unless user

      user.delayed_jobs.where(group_uuid: args.dig(:group_uuid)).find_each do |job|
        job.reschedule(advance: args.dig(:advance))
      end

      group_job = DelayedJob.scheduled_actions(user.id, Time.current.beginning_of_month, Time.current.end_of_month + 12.months).find { |group| group[:group_uuid] == args.dig(:group_uuid) }

      return unless Turbo::StreamsChannel.active_subscriptions_for?("my-contacts-scheduled-action-#{args.dig(:group_uuid)}")

      Turbo::StreamsChannel.broadcast_replace_to "my-contacts-scheduled-action-#{args.dig(:group_uuid)}",
                                                 target:  "action_time_min_#{args.dig(:group_uuid)}",
                                                 partial: 'my_contacts/broadcast/action_time',
                                                 locals:  {
                                                   id:        "action_time_min_#{args.dig(:group_uuid)}",
                                                   run_at:    group_job.dig(:min_run_at),
                                                   time_zone: user.client.time_zone
                                                 }
      Turbo::StreamsChannel.broadcast_replace_to "my-contacts-scheduled-action-#{args.dig(:group_uuid)}",
                                                 target:  "action_time_max_#{args.dig(:group_uuid)}",
                                                 partial: 'my_contacts/broadcast/action_time',
                                                 locals:  {
                                                   id:        "action_time_max_#{args.dig(:group_uuid)}",
                                                   run_at:    group_job.dig(:max_run_at),
                                                   time_zone: user.client.time_zone
                                                 }
    end
  end
end
