# frozen_string_literal: true

# app/lib/ringless_voicemail.rb
module RinglessVoicemail
  # receive a callback from SlyBroadcast and return a Hash
  # RinglessVoicemail.callback(params)
  def self.callback(args = {})
    response = {
      success:       false,
      account_id:    Rails.application.credentials[:slybroadcast][:uid],
      message_id:    '',
      status:        '',
      error_message: '',
      read_at:       Time.current
    }

    if args.dig(:var)
      var_hash = args[:var].split('|')

      if var_hash.length >= 5
        response = {
          success:       true,
          account_id:    Rails.application.credentials[:slybroadcast][:uid],
          message_id:    var_hash[0],
          status:        var_hash[2].casecmp?('ok') ? 'delivered' : var_hash[2].downcase,
          error_message: var_hash[3],
          read_at:       Time.strptime(var_hash[4], '%Y-%m-%d %H:%M:%S').in_time_zone('Eastern Time (US & Canada)').utc
        }
      end
    end

    response
  end

  # send a ringless voice mail
  # RinglessVoicemail.send_rvm(from_phone: String, to_phone: String, media_url: String)
  def self.send_rvm(args = {})
    from_phone = args.dig(:from_phone).to_s.clean_phone
    to_phone   = args.dig(:to_phone).to_s.clean_phone
    media_url  = args.dig(:media_url).to_s
    title      = (args.dig(:title) || 'Untitled').to_s
    media_type = (args.dig(:media_type) || 'wav').to_s
    response   = { success: false, session_id: '', number_of_phone: '', error_code: '', error_message: '' }

    if from_phone.present? && to_phone.present? && media_url.present?

      begin
        retries ||= 0
        conn      = Faraday.new(url: 'https://www.mobile-sphere.com/gateway/vmb.php')
        result    = conn.post '', {
          c_uid:       Rails.application.credentials[:slybroadcast][:uid],
          c_password:  Rails.application.credentials[:slybroadcast][:password],
          c_url:       args[:media_url].to_s,
          c_audio:     media_type,
          c_phone:     args[:to_phone].to_s,
          c_callerID:  args[:from_phone].to_s,
          c_date:      'now',
          c_title:     title,
          c_dispo_url: rvm_callback_url
        }

        split_result = result.body.split("\n")

        if split_result.is_a?(Array) && split_result.length >= 3
          response[:success]         = split_result[0].to_s.casecmp?('ok')
          response[:session_id]      = split_result[1].to_s.downcase.gsub('session_id=', '')
          response[:number_of_phone] = split_result[2].to_s
          response[:error_message]   = response[:success] ? '' : split_result[0].to_s.downcase
        end
      rescue Faraday::TimeoutError => e
        if (retries += 1) < 3
          retry
        else
          response[:error_message] = e.message

          ProcessError::Report.send(
            error_message: "RinglessVoicemail::SendRVM: #{e.message}",
            variables:     {
              args:     args.inspect,
              result:   result&.inspect,
              response: response.inspect,
              e:        e.inspect
            },
            file:          __FILE__,
            line:          __LINE__
          )
        end
      rescue StandardError => e
        # Something else happened
        response[:error_message] = e.message

        if e.message.casecmp?('execution expired') && (retries += 1) < 3
          retry
        else
          ProcessError::Report.send(
            error_message: "RinglessVoicemail::SendRVM: #{e.message}",
            variables:     {
              args:     args.inspect,
              result:   result&.inspect,
              response: response.inspect,
              e:        e.inspect
            },
            file:          __FILE__,
            line:          __LINE__
          )
        end
      end
    end

    response
  end
  # normal response
  # OK\nsession_id=9381694821\number of phone=1

  def self.rvm_callback_url
    Rails.application.routes.url_helpers.rvm_callback_voice_recording_url(host: self.url_host, protocol: self.url_protocol)
  end

  def self.url_host
    I18n.with_locale('chiirp') { I18n.t("tenant.#{Rails.env}.app_host") }
  end

  def self.url_protocol
    I18n.with_locale('chiirp') { I18n.t('tenant.app_protocol') }
  end
end
