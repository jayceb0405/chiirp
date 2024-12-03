# frozen_string_literal: true

# app/models/concerns/textable.rb
module Textable
  extend ActiveSupport::Concern
  include PaymentRequestable

  # send a text message
  #
  # Example:
  #   text_send(
  #     client:           Client,
  #     contact:          Contact,
  #     sending_user:     User,
  #     from_phone:       String,
  #     to_phone:         String,
  #     content:          String,
  #     image_id_array:   Array,
  #     triggeraction_id: Integer,
  #     msg_type:         String,
  #     automated:        Boolean
  #   )
  #
  # Arguments:
  #   (req) client:           (Client)
  #   (req) from_phone:       (String)
  #   (req) to_phone:         (Sttring)
  #   (opt) contact:          (Contact)
  #   (opt) sending_user:     (User)
  #   (opt) content:          (String)
  #   (opt) image_id_array:   (Array)
  #   (opt) triggeraction_id: (Integer)
  #   (opt) msg_type:         (String)
  #   (opt) automated:        (Boolean)
  #
  def text_send(args = {})
    client                  = args.dig(:client)
    contact                 = args.dig(:contact)
    from_phone              = args.dig(:from_phone).to_s
    to_phone                = args.dig(:to_phone).to_s
    content                 = args.dig(:content).to_s
    image_id_array          = [args.dig(:image_id_array) || []].flatten
    triggeraction_id        = args.dig(:triggeraction_id)
    aiagent_session_id      = args.dig(:aiagent_session_id)
    payment_request         = args.dig(:payment_request)
    msg_type                = args.dig(:msg_type).to_s
    automated               = args.dig(:automated).to_bool
    response                = { success: false, message: nil, error_code: '', error_message: '' }
    contact_estimate_id     = args.dig(:contact_estimate_id)
    contact_invoice_id      = args.dig(:contact_invoice_id)
    contact_job_id          = args.dig(:contact_job_id)
    contact_subscription_id = args.dig(:contact_subscription_id)
    contact_visit_id        = args.dig(:contact_visit_id)

    return response unless client.is_a?(Client) && client.active? && from_phone.present? && to_phone.present?

    # recharge credits if necessary
    client.recharge_credits

    # collect images & video
    image_id_hash, video_id_array = parse_image_id_array(contact, image_id_array)

    # replace all hashtags in content
    if contact.is_a?(Contact)
      content = contact.message_tag_replace(content, payment_request:)

      if contact_estimate_id.to_i.positive? && (contact_estimate = contact.estimates.find_by(id: contact_estimate_id))
        content = contact_estimate.message_tag_replace(content)
      end

      if contact_invoice_id.to_i.positive? && (contact_invoice = contact.invoices.find_by(id: contact_invoice_id))
        content = contact_invoice.message_tag_replace(content)
      end

      if contact_job_id.to_i.positive? && (contact_job = contact.jobs.find_by(id: contact_job_id))
        content = contact_job.message_tag_replace(content)
      end

      if contact_subscription_id.to_i.positive? && (contact_subscription = contact.subscriptions.find_by(id: contact_subscription_id))
        content = contact_subscription.message_tag_replace(content)
      end

      if contact_visit_id.to_i.positive? && (contact_visit = contact.visits.find_by(id: contact_visit_id))
        content = contact_visit.message_tag_replace(content)
      end
    end

    # replace all unwanted characters in content
    content = content.clean_smart_quotes if content.present?

    if content.present? || image_id_hash.present?

      if (client.current_balance.to_d / 100) >= (client.text_message_credits.to_d + (image_id_hash.length * client.text_image_credits.to_d))
        # account credits are sufficient
        result                   = SMS::Router.send(from_phone, to_phone, content, image_id_hash.values, client.tenant)
        response[:success]       = result.dig(:sid).to_s.present?
        response[:error_code]    = result[:error_code]
        response[:error_message] = result[:error_message]
      end

      if contact.is_a?(Contact) && result
        message = contact.messages.create(
          account_sid:     result[:account_sid],
          automated:,
          cost:            result[:cost].to_f,
          error_code:      result[:error_code],
          error_message:   result[:error_message],
          from_phone:,
          message:         content,
          message_sid:     result[:sid],
          msg_type:,
          num_segments:    result[:num_segments].to_i,
          read_at:         Time.current,
          read_at_user:    args.dig(:sending_user),
          status:          result[:status],
          to_phone:,
          triggeraction:   Triggeraction.find_by(id: triggeraction_id),
          aiagent_session: Aiagent::Session.find_by(id: aiagent_session_id),
          user:            args.dig(:sending_user)
        )

        image_id_hash.each_key do |id|
          message.attachments.create(contact_attachment_id: id)
        end

        if message.error_code.to_i.zero? && contact.contact_phones.pluck(:phone).include?(to_phone)
          contact.update(last_contacted: Time.current)
          contact.clear_unread_messages(args.dig(:sending_user) || contact.user) unless automated
        end

        # update Contact list in Message Central and navbar
        show_live_messenger = ShowLiveMessenger.new(message:)
        show_live_messenger.queue_broadcast_active_contacts
        show_live_messenger.queue_broadcast_message_thread_message

        response[:message] = message
      end
    end

    #
    # send videos
    #
    if (client.current_balance.to_d / 100) >= (video_id_array.length * client.text_image_credits.to_d)
      # account credits are sufficient
      app_host = I18n.with_locale(client.tenant) { I18n.t("tenant.#{Rails.env}.app_host") }

      video_id_array.each do |id|
        result = SMS::Router.send(
          from_phone,
          to_phone,
          Rails.application.routes.url_helpers.messages_show_video_url(id, host: app_host),
          [],
          client.tenant
        )

        if contact.is_a?(Contact) && result
          message = contact.messages.create(
            account_sid:   result[:account_sid],
            automated:,
            cost:          result[:cost].to_f,
            error_code:    result[:error_code],
            error_message: result[:error_message],
            from_phone:,
            message:       '',
            message_sid:   result[:sid],
            msg_type:,
            num_segments:  result[:num_segments].to_i,
            read_at:       Time.current,
            read_at_user:  args.dig(:sending_user),
            status:        result[:status],
            to_phone:,
            triggeraction: Triggeraction.find_by(id: triggeraction_id),
            user:          args.dig(:sending_user)
          )

          message.attachments.create(contact_attachment_id: id)

          if message.error_code.to_i.zero? && contact.contact_phones.pluck(:phone).include?(to_phone)
            contact.update(last_contacted: Time.current)
            contact.clear_unread_messages(args.dig(:sending_user) || contact.user) unless automated
          end

          # update Contact list in Message Central and navbar
          show_live_messenger = ShowLiveMessenger.new(message:)
          show_live_messenger.queue_broadcast_active_contacts
          show_live_messenger.queue_broadcast_message_thread_message
        end
      end
    end

    response
  end

  # parse image_id_array for image_id_hash & video_id_array
  #
  # Example:
  #   image_id_hash, video_id_array = parse_image_id_array(Contact, Array)
  #
  #   image_id_hash:  { contact_attachment.id => image_url, ... }
  #   video_id_array: [ contact_attachment.id, ... ]
  def parse_image_id_array(contact, image_id_array)
    image_id_hash  = {}
    video_id_array = []

    if contact.is_a?(Contact)

      contact.contact_attachments.where(id: image_id_array).find_each do |contact_attachment|
        if contact_attachment.image.resource_type.casecmp?('video')
          video_id_array << contact_attachment.id
        else
          image_id_hash[contact_attachment.id] = contact_attachment.image.url(secure: true)
        end
      end
    end

    [image_id_hash, video_id_array]
  end
end
