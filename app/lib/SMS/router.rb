# frozen_string_literal: true

# app/lib/SMS/router.rb
module SMS
  # methods used to route SMS/MMS messaging through Bandwidth/Twilio
  module Router
    delegate :url_helpers, to: 'Rails.application.routes'

    def self.attach_media(args = {})
      message      = args.dig(:message)
      media_array  = args.dig(:media_array)
      image_result = ''

      return unless message.is_a?(Messages::Message) && media_array.is_a?(Array) && media_array.present? && (twnumber = Twnumber.find_by(phonenumber: message.to_phone))

      media_array.map { |m| m[-5, 5] == '.smil' ? nil : m }.compact_blank.each do |m|
        begin
          case twnumber.phone_vendor
          when 'twilio'
            contact_attachment = message.contact.contact_attachments.create!(remote_image_url: m)
          when 'bandwidth'
            contact_attachment = SMS::Bandwidth.attach_media_to_contact(contact: message.contact, media: m)
          end

          message.attachments.create!(contact_attachment_id: contact_attachment.id) unless contact_attachment.nil?
        rescue Cloudinary::CarrierWave::UploadError => e
          image_result = 'Image file upload error'

          ProcessError::Report.send(
            error_message: "Router::AttachMedia::Cloudinary::CarrierWave::UploadError: #{image_result}",
            variables:     {
              e:           e.inspect,
              e_message:   e.message,
              media:       m,
              media_array: media_array.inspect,
              message:     message.inspect,
              file:        __FILE__,
              line:        __LINE__
            }
          )
        rescue ActiveRecord::RecordInvalid => e
          image_result = e.inspect.include?('Image File size should be less than 5 MB') ? 'Image file too large - Max: 5 MB' : 'Image file upload error'

          ProcessError::Report.send(
            error_message: "Router::AttachMedia::ActiveRecord::RecordInvalid: #{image_result}",
            variables:     {
              e:           e.inspect,
              e_message:   e.message,
              media:       m,
              media_array: media_array.inspect,
              message:     message.inspect,
              file:        __FILE__,
              line:        __LINE__
            }
          )
        rescue StandardError => e
          image_result = 'Image file upload error'

          ProcessError::Report.send(
            error_message: "Router::AttachMedia::StandardError: #{image_result}",
            variables:     {
              e:           e.inspect,
              e_message:   e.message,
              media:       m,
              media_array: media_array.inspect,
              message:     message.inspect,
              file:        __FILE__,
              line:        __LINE__
            }
          )
        end
      end

      message.update(message: "#{message.message} (#{image_result})") if image_result.length.positive?
    end

    # process message callback from vendor
    def self.callback(**args)
      args = args.deep_symbolize_keys

      if args.dig(:_json)
        SMS::Bandwidth.message_callback(**args)
      elsif args.dig(:batch_id)
        SMS::SinchSms.new.message_callback args
      elsif args.dig(:AccountSid)
        SMS::TwilioSms.callback args
      else
        {
          success:       false,
          message_sid:   '',
          status:        '',
          error_code:    '',
          error_message: ''
        }
      end
    end

    def self.receive(args = {})
      # receive an incoming text message
      # SMS::Router.receive()
      response = {
        success:       false,
        message:       {
          from_phone:    '',
          to_phone:      '',
          content:       '',
          media_array:   [],
          segment_count: 0,
          status:        'failed',
          message_sid:   '',
          account_sid:   '',
          to_city:       '',
          to_state:      '',
          to_zip:        '',
          to_country:    '',
          from_city:     '',
          from_state:    '',
          from_zip:      '',
          from_country:  ''
        },
        error_code:    '',
        error_message: ''
      }

      if args.dig(:AccountSid) && args.dig(:AccountSid) == Rails.application.credentials[:twilio][:sid]
        response = SMS::TwilioSms.receive args
      elsif args.dig(:_json).is_a?(Array) && args.dig(:_json)[0].dig(:message, :applicationId) == ENV['BANDWIDTH_MESSAGING_APPLICATION_ID']
        response = SMS::Bandwidth.receive args
      end

      response
    end

    def self.send(from_phone, to_phone, message_text = '', media_url_array = [], tenant = 'chiirp')
      # send a text message
      # SMS::Router.send(from_phone, to_phone, message_text, media_url_array, tenant)
      response = {
        sid:           '',
        account_sid:   '',
        status:        'undelivered',
        cost:          0.0,
        num_segments:  0,
        error_code:    '',
        error_message: ''
      }

      case from_phone
      when Twnumber
        # from_phone is good as it is
      when String
        from_phone = Twnumber.find_by(phonenumber: from_phone)
      when Integer
        from_phone = Twnumber.find_by(id: from_phone)
      else
        from_phone = nil
      end

      if from_phone
        # catch messages in dev/test to prevent leaking random SMS to clients/contacts
        if !Rails.env.production? && ENV.fetch('SUPER_USER_PHONES', '8022823191').split(',').exclude?(to_phone)
          message_text.prepend "To: #{to_phone}\n"
          to_phone = ENV.fetch('SUPER_USER_PHONES', '8022823191').split(',').first
        end

        case from_phone.phone_vendor
        when 'twilio'
          response = SMS::TwilioSms.send from_phone.phonenumber, to_phone, message_text, media_url_array, tenant
        when 'bandwidth'
          response = SMS::Bandwidth.send from_phone.phonenumber, to_phone, message_text, media_url_array, tenant
        end
      end

      response
    end

    def self.status_options
      ['', 'accepted', 'queued', 'sending', 'sent', 'delivered', 'undelivered', 'failed']
    end

    def self.subscription_callback(args = {})
      SMS::Bandwidth.subscription_callback args
    end

    # update status for a specific Messages::Message
    # SMS::Router.update_status(Messages::Message)
    def self.update_status(message)
      response = { success: true, error_code: '', error_message: '', message_response: nil }

      twnumber = if message.status == 'received'
                   Twnumber.find_by(phonenumber: message.to_phone)
                 else
                   Twnumber.find_by(phonenumber: message.from_phone)
                 end

      if twnumber
        case twnumber.phone_vendor
        when 'twilio'
          response = SMS::TwilioSms.update_status message
        when 'bandwidth'
          response = SMS::Bandwidth.update_status message
        end
      end

      response
    end
  end
end
