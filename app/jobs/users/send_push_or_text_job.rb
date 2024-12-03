# frozen_string_literal: true

# app/jobs/users/send_push_or_text_job.rb
module Users
  class SendPushOrTextJob < ApplicationJob
    # destroy a Contact
    # Users::SendPushOrTextJob.perform_later()
    # Users::SendPushOrTextJob.set(wait_until: 1.day.from_now).perform_later()
    # Users::SendPushOrTextJob.set(wait_until: 1.day.from_now, priority: 0).perform_later()
    # Users::SendPushOrTextJob.perform_now()

    def initialize(**args)
      super

      @process = (args.dig(:process).presence || 'send_push_or_text').to_s
    end

    # perform the ActiveJob
    #   (req) content:          (String)
    #   (req) user_id:          (Integer)
    #
    #   (opt) automated:        (Boolean)
    #   (opt) contact_id:       (Integer)
    #   (opt) force:            (Boolean)
    #   (opt) from_phone:       (String)
    #   (opt) image_id_array:   (Array)
    #   (opt) msg_type:         (String)
    #   (opt) ok2push:          (Boolean)
    #   (opt) ok2text:          (Boolean)
    #   (opt) send_to:          (String)
    #   (opt) title:            (String)
    #   (opt) to_phone:         (String)
    #   (opt) triggeraction_id: (Integer)
    #   (opt) sending_user:     (User)
    #   (opt) url:              (String)
    def perform(**args)
      super

      return false if args.dig(:content).to_s.blank? || args.dig(:user_id).to_i.zero? || (user = User.find_by(id: args[:user_id])).nil? || user.suspended? || !user.client.active?

      pushed_ok = Users::SendPushJob.perform_now(**args)
      texted_ok = false

      unless pushed_ok
        args[:content] = [args.dig(:title).to_s.present? ? "#{args[:title]}:" : '', args.dig(:content).to_s, args.dig(:url).to_s.present? ? "Link: #{args[:url]}" : ''].compact_blank.join(' ')
        texted_ok      = user.send_text(args)
      end

      pushed_ok || texted_ok
    end
  end
end
