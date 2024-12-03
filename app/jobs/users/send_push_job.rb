# frozen_string_literal: true

# app/jobs/users/send_push_job.rb
module Users
  class SendPushJob < ApplicationJob
    # destroy a Contact
    # Users::SendPushJob.set(wait_until: 1.day.from_now).perform_later()
    # Users::SendPushJob.set(wait_until: 1.day.from_now, priority: 0).perform_later()

    def initialize(**args)
      super

      @process = (args.dig(:process).presence || 'send_push').to_s
    end

    # perform the ActiveJob
    #   (opt) contact_id: (Integer)
    #   (req) content:    (String)
    #   (opt) ok2push:    (Boolean)
    #   (opt) target:     (Array)
    #   (opt) title:      (String)
    #   (opt) type:       (String)
    #   (opt) url:        (String)
    #   (req) user_id:    (Integer)
    def perform(**args)
      super

      return false unless args.dig(:ok2push).nil? || args.dig(:ok2push).to_bool
      return false unless args.dig(:user_id).to_i.positive? && (user = User.find_by(id: args[:user_id].to_i)) && !user.suspended? && user.client.active?

      target = if args.dig(:target).is_a?(Array)
                 args[:target].map(&:downcase)
               else
                 args.dig(:target).is_a?(String) ? args[:target].delete(',').downcase.split : %w[mobile desktop slack]
               end

      mobile_pushed_ok  = send_mobile_push(user:, args:) if target.include?('mobile')
      desktop_pushed_ok = send_desktop_push(user:, args:) if target.include?('desktop') && args.dig(:content).to_s.present?
      slack_pushed_ok   = send_slack_push(user:, args:) if target.include?('slack') && args.dig(:content).to_s.present?

      desktop_pushed_ok || mobile_pushed_ok || slack_pushed_ok
    end

    private

    def send_desktop_push(user:, args:)
      os_client = Notifications::OneSignal::V1::Base.new([user.id])
      os_client.send_push(
        title:   args.dig(:title).to_s,
        content: args.dig(:content).to_s,
        url:     args.dig(:url).to_s
      )
      UserCable.new.broadcast user.client, user, { toastr: ['info', "#{args.dig(:title)}: #{args.dig(:content)}"] } if args.dig(:title).to_s.present? || args.dig(:content).to_s.present?

      os_client.success?
    end

    def send_mobile_push(user:, args:)
      pm_client = Notifications::PushMobile.new(user.user_pushes.where(target: 'mobile').pluck(Arel.sql("data -> 'mobile_key'")))
      pm_client.send_push(
        badge:      Messages::Message.unread_messages_by_user(user.id).group(:contact_id).count.values.sum,
        contact_id: args.dig(:contact_id).to_i,
        content:    args.dig(:content).to_s,
        title:      args.dig(:title).to_s,
        type:       args.dig(:type).to_s,
        url:        args.dig(:url).to_s
      )

      pm_client.success?
    end

    def send_slack_push(user:, args:)
      user.send_slack(
        title:   args.dig(:title).to_s,
        content: args.dig(:content).to_s,
        url:     args.dig(:url).to_s
      )
    end
  end
end
