# frozen_string_literal: true

# app/models/messages/send_message.rb
module Messages
  class SendMessage
    # Messages::SendMessage.new()
    #   (req) from_phone:           (String)
    #   (req) message:              (String)
    #   (opt) msg_delay:            (DataTime)     date/time when message should be sent out
    #   (opt) msg_type:             (String)       (fb: Facebook, ggl: Google, otherwise text)
    #   (opt) to_phone:             (String)       space separated string of phone numbers
    #   (opt) email_template_id:    (Integer)      email template ID to use
    #   (opt) email_template_yield: (String)       email template yeild string
    def initialize(args = {})
      @image_ids              = []
      @from_phone             = args.dig(:from_phone).to_s
      @message                = args.dig(:message).to_s
      @msg_delay              = args.dig(:msg_delay)
      @msg_type               = args.dig(:msg_type).to_s
      @payment_request        = args.dig(:payment_request).to_d
      @response_bubble        = { message: '', meta: '', msg_type: '' }
      @to_phone               = args.dig(:to_phone).to_s.strip
      @file_attachments       = args.dig(:file_attachments) || []
      @email_template_id      = args.dig(:email_template_id).to_i
      @email_template_subject = args.dig(:email_template_subject).to_s.strip
      @email_template_subject = nil if @email_template_subject.empty?
      @email_template_yield   = args.dig(:email_template_yield).to_s.strip
      @email_template_cc      = args.dig(:email_template_cc).to_s.strip
      @email_template_bcc     = args.dig(:email_template_bcc).to_s.strip
      @voice_recording        = nil
    end

    # send a message
    # Messages::SendMessage.new.send()
    #   (req) contact_ids:         (Array)        Contact IDs of Contacts to send message to
    #           ~ or ~
    #         contact_id:          (Integer)
    #   (opt) file_attachments:    (Array)        [ { id: Integer, type: String, url: String }, ... ] (type: "client", "user", "contact")
    #   (opt) user_id:             (Integer)      User ID who is sending message (defaults to User assigned to Contact)
    #   (opt) voice_recording_id:  (Integer)
    def send(args = {})
      return @response_bubble unless args.dig(:contact_ids).present? || args.dig(:contact_id).present?
      return @response_bubble unless @from_phone.present? || %w[email fb ggl].include?(@msg_type)

      Contact.where(id: parse_contact_ids(args.dig(:contact_ids), args.dig(:contact_id))).find_each do |contact|
        user             = User.find_by(id: args.dig(:user_id) || contact.user_id)
        @image_ids       = parse_image_ids(contact, user, args.dig(:file_attachments))
        @voice_recording = args.dig(:voice_recording_id).to_i.positive? ? user.client.voice_recordings.find_by(id: args.dig(:voice_recording_id)) : nil

        send_message(contact, user)
        send_rvm(contact, user)
        contact.update(sleep: false)
      end

      @response_bubble
    end

    private

    def parse_contact_ids(contact_ids, contact_id)
      if contact_ids.present?
        contact_ids.split.map(&:to_i)
      elsif contact_id.to_i.positive?
        [contact_id.to_i]
      else
        []
      end
    end

    def parse_image_ids(contact, user, file_attachments)
      image_ids = []

      file_attachments.each do |fa|
        case fa[:type].to_s
        when 'user'
          file_attachment = user.user_attachments.find_by(id: fa[:id].to_i)
        when 'contact'
          file_attachment = contact.contact_attachments.find_by(id: fa[:id].to_i)
        end

        next unless file_attachment

        case fa[:type].to_s
        when 'user'
          begin
            contact_attachment = contact.contact_attachments.new
            contact_attachment.remote_image_url = file_attachment.image.url(secure: true)
            contact_attachment.save
            image_ids << contact_attachment.id
          rescue Cloudinary::CarrierWave::UploadError => e
            e.set_backtrace(BC.new.clean(caller))

            Appsignal.report_error(e) do |transaction|
              # Only needed if it needs to be different or there's no active transaction from which to inherit it
              Appsignal.set_action('Messages::SendMessage.parse_image_ids')

              # Only needed if you want to set different arguments or there's no active transaction from which to inherit it
              Appsignal.add_params({ contact:, user:, file_attachments: })

              Appsignal.set_tags(
                error_level: 'error',
                error_code:  0
              )
              Appsignal.add_custom_data(
                fa:              fa.inspect,
                file_attachment: file_attachment.inspect,
                file:            __FILE__,
                line:            __LINE__
              )
            end
          rescue ActiveRecord::RecordInvalid => e
            e.set_backtrace(BC.new.clean(caller))

            Appsignal.report_error(e) do |transaction|
              # Only needed if it needs to be different or there's no active transaction from which to inherit it
              Appsignal.set_action('Messages::SendMessage.parse_image_ids')

              # Only needed if you want to set different arguments or there's no active transaction from which to inherit it
              Appsignal.add_params({ contact:, user:, file_attachments: })

              Appsignal.set_tags(
                error_level: 'error',
                error_code:  0
              )
              Appsignal.add_custom_data(
                fa:              fa.inspect,
                file_attachment: file_attachment.inspect,
                file:            __FILE__,
                line:            __LINE__
              )
            end
          rescue StandardError => e
            e.set_backtrace(BC.new.clean(caller))

            Appsignal.report_error(e) do |transaction|
              # Only needed if it needs to be different or there's no active transaction from which to inherit it
              Appsignal.set_action('Messages::SendMessage.parse_image_ids')

              # Only needed if you want to set different arguments or there's no active transaction from which to inherit it
              Appsignal.add_params({ contact:, user:, file_attachments: })

              Appsignal.set_tags(
                error_level: 'error',
                error_code:  0
              )
              Appsignal.add_custom_data(
                fa:              fa.inspect,
                file_attachment: file_attachment.inspect,
                file:            __FILE__,
                line:            __LINE__
              )
            end
          end
        when 'contact'
          image_ids << file_attachment.id
        end
      end

      image_ids
    end

    def parse_run_at(user)
      @msg_delay.blank? ? 1.hour.ago : Time.use_zone(user.client.time_zone) { Chronic.parse(@msg_delay) }
    end

    def send_message(contact, user)
      return unless (@message.present? || @email_template_id.present?) || @image_ids.present?

      case @msg_type
      when 'email'
        send_email_message(contact, user)
      when 'fb'
        send_fb_message(contact, user)
      when 'ggl'
        send_ggl_message(contact, user)
      else
        send_text_message(contact, user)
      end
    end

    def send_email_message(contact, user)
      return unless contact.is_a?(Contact) && user.is_a?(User) && @email_template_id.present?

      email_template = user.client.email_templates.find_by(id: @email_template_id)

      @response_bubble[:message] = @email_template_subject || email_template&.subject
      @response_bubble[:msg_type] = 'emailout'
      @response_bubble[:meta] = "(queued) #{Friendly.new.date(Time.current, user.client.time_zone, true, true)} #{user.firstname_last_initial}"

      contact.delay(
        run_at:     parse_run_at(user),
        priority:   DelayedJob.job_priority('send_email'),
        queue:      DelayedJob.job_queue('send_email'),
        contact_id: contact.id,
        user_id:    contact.user_id,
        process:    'send_email',
        data:       { email_template_id: @email_template_id, contact:, user: }
      ).send_email(
        email_template_id:    @email_template_id,
        email_template_yield: @email_template_yield,
        file_attachments:     @file_attachments,
        subject:              @email_template_subject,
        cc_email:             @email_template_cc,
        bcc_email:            @email_template_bcc,
        from_email:           user.email,
        payment_request:      @payment_request
      )
    end

    def send_fb_message(contact, user)
      return unless contact.is_a?(Contact) && user.is_a?(User) && (contact_fb_page = contact.fb_pages.order(updated_at: :desc).first)

      @response_bubble[:message]  = @message
      @response_bubble[:msg_type] = 'fbout'
      @response_bubble[:meta]     = "(queued) #{Friendly.new.date(Time.current, user.client.time_zone, true, true)} #{user.firstname_last_initial}"

      contact.delay(
        run_at:     parse_run_at(user),
        priority:   DelayedJob.job_priority('send_fb_messsage'),
        queue:      DelayedJob.job_queue('send_fb_messsage'),
        contact_id: contact.id,
        user_id:    contact.user_id,
        process:    'send_fb_messsage',
        data:       { content: @message, image_ids: @image_ids, msg_type: @response_bubble[:msg_type], page_id: contact_fb_page.page_id, page_scoped_id: contact_fb_page.page_scoped_id, page_token: contact_fb_page.page_token }
      ).send_fb_message(
        content:        @message,
        image_ids:      @image_ids,
        msg_type:       @response_bubble[:msg_type],
        page_id:        contact_fb_page.page_id,
        page_scoped_id: contact_fb_page.page_scoped_id,
        page_token:     contact_fb_page.page_token
      )
    end

    def send_ggl_message(contact, user)
      return unless contact.is_a?(Contact) && user.is_a?(User) && (ggl_conversation = contact.ggl_conversations.order(updated_at: :desc).first)

      @response_bubble[:message]  = @message
      @response_bubble[:msg_type] = 'gglout'
      @response_bubble[:meta]     = "(queued) #{Friendly.new.date(Time.current, user.client.time_zone, true, true)} #{user.firstname_last_initial}"

      contact.delay(
        run_at:     parse_run_at(user),
        priority:   DelayedJob.job_priority('send_ggl_message'),
        queue:      DelayedJob.job_queue('send_ggl_message'),
        contact_id: contact.id,
        user_id:    contact.user_id,
        process:    'send_ggl_message',
        data:       { content: @message, image_ids: @image_ids, msg_type: @response_bubble[:msg_type], conversation_id: ggl_conversation.conversation_id, page_scoped_id: ggl_conversation.agent_id }
      ).send_ggl_message(
        content:         @message,
        image_ids:       @image_ids,
        msg_type:        @response_bubble[:msg_type],
        conversation_id: ggl_conversation.conversation_id,
        agent_id:        ggl_conversation.agent_id
      )
    end

    def send_rvm(contact, user)
      return unless contact.is_a?(Contact) && user.is_a?(User) && @voice_recording

      @response_bubble[:message]  = "Ringless VM: #{@voice_recording.recording_name}"
      @response_bubble[:meta]     = "#{ActionController::Base.helpers.number_to_phone(to_phone_numbers(contact).first)} (queued) #{Friendly.new.date(Time.current, user.client.time_zone, true, true)} #{user.firstname_last_initial}"
      @response_bubble[:msg_type] = 'rvmout'

      to_phone_numbers(contact).each do |to_phone|
        contact.delay(
          run_at:              parse_run_at(user),
          priority:            DelayedJob.job_priority('send_rvm'),
          queue:               DelayedJob.job_queue('send_rvm'),
          contact_id:          contact.id,
          user_id:             contact.user_id,
          triggeraction_id:    0,
          contact_campaign_id: 0,
          data:                { content: @voice_recording.recording_name, voice_recording_id: @voice_recording.id, voice_recording_url: @voice_recording.url },
          process:             'send_rvm'
        ).send_rvm(
          from_phone:          @from_phone,
          message:             @voice_recording.recording_name,
          to_phone:,
          user:,
          voice_recording_id:  @voice_recording.id,
          voice_recording_url: @voice_recording.url
        )
      end
    end

    def send_text_message(contact, user)
      return unless contact.is_a?(Contact) && user.is_a?(User)

      @response_bubble[:msg_type] = 'textout'
      @response_bubble[:message]  = @message
      @response_bubble[:meta]     = "#{ActionController::Base.helpers.number_to_phone(to_phone_numbers(contact).first)} (queued) #{Friendly.new.date(Time.current, user.client.time_zone, true, true)} #{user.firstname_last_initial}"

      to_phone_numbers(contact).each do |to_phone|
        contact.delay(
          run_at:     parse_run_at(user),
          priority:   DelayedJob.job_priority('send_text'),
          queue:      DelayedJob.job_queue('send_text'),
          contact_id: contact.id,
          user_id:    contact.user_id,
          process:    'send_text',
          data:       { content: @message, from_phone: @from_phone, image_ids: @image_ids, msg_type: @response_bubble[:msg_type], payment_request: @payment_request, to_phone: }
        ).send_text(
          content:         @message,
          from_phone:      @from_phone,
          image_id_array:  @image_ids,
          msg_type:        @response_bubble[:msg_type],
          payment_request: @payment_request,
          to_phone:,
          user:
        )
      end
    end

    def to_phone_numbers(contact)
      if @to_phone.present?
        [@to_phone]
      else
        [contact.primary_phone&.phone.to_s]
      end
    end
  end
end
