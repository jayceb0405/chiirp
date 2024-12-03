# frozen_string_literal: true

# app/lib/voice/bandwidth.rb
module Voice
  # process API calls to Bandwidth to support voice processing
  module Bandwidth
    class VoiceBandwidthError < StandardError; end

    # place a call
    # Voice::Bandwidth.call(from_phone: String, to_phone: String, answer_url: String)
    # (req) answer_url:        (String)
    # (req) from_phone:        (String)
    # (req) to_phone:          (String)
    # (opt) disconnect_url:    (String)
    # (opt) machine_detection: (Boolean)
    # (opt) parent_call_id:    (String)
    # (opt) ring_duration:     (Integer)
    def self.call(args = {})
      answer_url     = args.dig(:answer_url).to_s
      disconnect_url = args.dig(:disconnect_url).to_s
      from_phone     = args.dig(:from_phone).to_s.clean_phone
      response       = { success: false, error_code: 0, error_message: '', call_id: '' }
      to_phone       = args.dig(:to_phone).to_s.clean_phone

      return response if from_phone.blank? || to_phone.blank? || answer_url.empty?

      response[:success], response[:error_code], response[:error_message] = Retryable.with_retries(
        rescue_class:          [Faraday::TimeoutError, Faraday::ConnectionFailed],
        retry_skip_reason:     'getaddrinfo: Name or service not known',
        error_message_prepend: 'Voice::Bandwidth::Call',
        current_variables:     {
          answer_url:     answer_url.inspect,
          args:           args.inspect,
          disconnect_url: disconnect_url.inspect,
          from_phone:     from_phone.inspect,
          response:       response.inspect,
          to_phone:       to_phone.inspect,
          parent_file:    __FILE__,
          parent_line:    __LINE__
        }
      ) do
        body = {
          from:          "+1#{from_phone}",
          to:            "+1#{to_phone}",
          answerUrl:     answer_url.to_s, # &callback_source=call-progress-events
          answerMethod:  'POST',
          applicationId: self.application_id,
          callTimeout:   (args.dig(:ring_duration) || 20).to_i
        }
        body[:disconnectUrl] = disconnect_url if disconnect_url.present?

        if args.dig(:machine_detection).to_bool
          body[:machineDetection] = {
            mode:               'sync',
            detectionTimeout:   5,
            silenceTimeout:     5,
            speechThreshold:    5,
            speechEndThreshold: 2
          }
        end

        # Rails.logger.info "Bandwidth Call Body: #{body.inspect} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"

        result = Faraday.post("#{self.base_voice_url}/calls") do |req|
          req.headers['Authorization'] = "Basic #{self.basic_auth}"
          req.headers['Content-Type']  = 'application/json; charset=utf-8'
          req.body                     = body.to_json
        end

        if result.success?
          response[:success] = true
          call_id            = JSON.parse(result.body).dig('callId').to_s

          if call_id.present? && args.dig(:parent_call_id).present?
            vr_client          = Voice::RedisPool.new(args[:parent_call_id].to_s)
            vr_client.call_ids = vr_client.call_ids << call_id
          end
        else
          error = VoiceBandwidthError.new("Could not complete call from: #{from_phone} to: #{to_phone}")
          error.set_backtrace(BC.new.clean(caller))

          Appsignal.report_error(error) do |transaction|
            # Only needed if it needs to be different or there's no active transaction from which to inherit it
            Appsignal.set_action('Voice::Bandwidth.call')

            # Only needed if you want to set different arguments or there's no active transaction from which to inherit it
            Appsignal.add_params(args)

            Appsignal.set_tags(
              error_level: 'error',
              error_code:  0
            )
            Appsignal.add_custom_data(
              answer_url:,
              disconnect_url:,
              from_phone:,
              response:,
              result:         JSON.parse(result.body),
              to_phone:,
              file:           __FILE__,
              line:           __LINE__
            )
          end
        end
      end

      response
    end

    # respond to caller with option to leave voicemail
    # Voice::Bandwidth.call_accept_voicemail(transcribe_url: String)
    # (req) transcribe_url:      (String)
    # (opt) content:             (String)
    # (opt) voice_recording_url: (String)
    def self.call_accept_voicemail(args = {})
      return self.hangup if args.dig(:transcribe_url).blank?

      response = if args.dig(:voice_recording_url).present?
                   "<PlayAudio>#{args[:voice_recording_url]}</PlayAudio>"
                 else
                   self.xml_speak("#{args.dig(:content).present? ? args[:content] : 'No one is available to take your call.'} Please leave a message after the tone. Press star to complete or simply hang up.")
                 end

      self.xml_response_wrap [
        response,
        '<Pause duration="1" />',
        '<PlayAudio>https://media.chiirp.com/video/upload/v1645564095/samples/beep.mp3</PlayAudio>',
        self.xml_voicemail(args[:transcribe_url].to_s),
        self.xml_speak('I did not receive a recording.')
      ]
    end

    # bridge 2 calls together
    # Voice::Bandwidth.call_bridge(call_id: String, contact_complete_url: String, user_complete_url: String)
    # (req) call_id:              (String)
    # (req) contact_complete_url: (String)
    # (req) user_complete_url:    (String)
    # (opt) content:              (String)
    def self.call_bridge(args = {})
      return self.hangup if args.dig(:call_id).blank? || args.dig(:contact_complete_url).blank? || args.dig(:user_complete_url).blank?

      self.xml_response_wrap [
        args.dig(:content).to_s.present? ? self.xml_speak(args[:content]) : '',
        "<Bridge bridgeTargetCompleteUrl=\"#{args[:contact_complete_url]}\" bridgeCompleteUrl=\"#{args[:user_complete_url]}\">#{args[:call_id]}</Bridge>"
      ]
    end

    # cancel a current call
    # Voice::Bandwidth.call_cancel(String)
    def self.call_cancel(call_id)
      response = { success: false, error_code: 0, error_message: '' }

      return response if call_id.blank?

      response[:success], response[:error_code], response[:error_message] = Retryable.with_retries(
        rescue_class:          [Faraday::TimeoutError, Faraday::ConnectionFailed],
        retry_skip_reason:     'getaddrinfo: Name or service not known',
        error_message_prepend: 'Voice::Bandwidth::CallCancel',
        current_variables:     {
          call_id:     call_id.inspect,
          parent_file: __FILE__,
          parent_line: __LINE__
        }
      ) do
        body = {
          state: 'completed'
        }

        result = Faraday.post("#{self.base_voice_url}/calls/#{call_id}") do |req|
          req.headers['Authorization'] = "Basic #{self.basic_auth}"
          req.headers['Content-Type']  = 'application/json; charset=utf-8'
          req.body                     = body.to_json
        end

        if result.success? || result.status.to_i == 404
          response[:success] = true
        else
          error = VoiceBandwidthError.new("Could not cancel call id: #{call_id}")
          error.set_backtrace(BC.new.clean(caller))

          Appsignal.report_error(error) do |transaction|
            # Only needed if it needs to be different or there's no active transaction from which to inherit it
            Appsignal.set_action('Voice::Bandwidth.call_cancel')

            # Only needed if you want to set different arguments or there's no active transaction from which to inherit it
            Appsignal.add_params({ call_id: })

            Appsignal.set_tags(
              error_level: 'error',
              error_code:  0
            )
            Appsignal.add_custom_data(
              response: response,
              result:   JSON.parse(result.body),
              file:     __FILE__,
              line:     __LINE__
            )
          end
        end
      end
    end

    # calculate the length of a call
    # Voice::Bandwidth.call_duration(start_time, end_time)
    def self.call_duration(start_time, end_time)
      (start_time && end_time ? Chronic.parse(end_time) - Chronic.parse(start_time) : 0).to_i
    end

    # connect incoming call to User
    # Voice::Bandwidth.call_incoming_connect
    # (opt) announcement_url: (String)
    # (opt) ring_duration:    (Integer)
    # (opt) vm_greeting:      (String)
    # (opt) transcribe_url:   (String)
    def self.call_incoming_connect(args = {})
      xml_array  = []
      xml_array << "<PlayAudio>#{args[:announcement_url]}</PlayAudio>" if args.dig(:announcement_url).present?
      xml_array << "<Ring duration=\"#{args.dig(:ring_duration) || 30}\" />"

      if args.dig(:vm_greeting).present?
        xml_array += [
          args[:vm_greeting].to_s[0, 8] == 'https://' ? "<PlayAudio>#{args[:vm_greeting]}</PlayAudio>" : self.xml_speak(args[:vm_greeting].to_s),
          '<Pause duration="1" />',
          '<PlayAudio>https://media.chiirp.com/video/upload/v1645564095/samples/beep.mp3</PlayAudio>'
        ]
      end

      xml_array << self.xml_voicemail(args[:transcribe_url].to_s) if args.dig(:transcribe_url).present?

      self.xml_response_wrap xml_array
    end

    # connect a previously initiated outgoing call with another phone number
    # Voice::Bandwidth.call_outgoing_connect(from_phone: String, to_phone: String, callback_url: String, disconnect_url: String)
    # (req) from_phone:     (String)
    # (req) to_phone:       (String)
    # (req) callback_url:   (String)
    # (req) disconnect_url: (String)
    # (opt) content:        (String)
    # (opt) ring_duration:  (Integer)
    def self.call_outgoing_connect(args = {})
      return self.hangup if args.dig(:from_phone).blank? || args.dig(:to_phone).blank? || args.dig(:callback_url).blank? || args.dig(:disconnect_url).blank?

      self.call(
        from_phone:     args[:from_phone].to_s,
        to_phone:       args[:to_phone].to_s,
        ring_duration:  args.dig(:ring_duration) || 60,
        answer_url:     args[:callback_url].to_s,
        disconnect_url: args[:disconnect_url].to_s
      )

      self.xml_response_wrap [
        '<Pause duration="1" />',
        args.dig(:content).to_s.present? ? self.xml_speak(args[:content]) : self.xml_speak('Please wait while your call is connected.'),
        "<Ring duration=\"#{(args.dig(:ring_duration) || 60).to_i}\" />"
      ]
    end

    # redirect an existing call to a new URL
    # Voice::Bandwidth.call_redirect(call_id: String, redirect_url: String)
    # (req) call_id:      (String)
    # (req) redirect_url: (String)
    def self.call_redirect(args = {})
      return if args.dig(:call_id).blank? && args.dig(:redirect_url).blank?

      _x, _y, _z = Retryable.with_retries(
        rescue_class:          [Faraday::TimeoutError, Faraday::ConnectionFailed],
        retry_skip_reason:     'getaddrinfo: Name or service not known',
        error_message_prepend: 'Voice::Bandwidth::Call',
        current_variables:     {
          args:        args.inspect,
          parent_file: __FILE__,
          parent_line: __LINE__
        }
      ) do
        data = {
          state:       'active',
          redirectUrl: args[:redirect_url]
        }
        Faraday.post("#{self.base_voice_url}/calls/#{args[:call_id]}") do |req|
          req.headers['Content-Type']  = 'application/json; charset=utf-8'
          req.headers['Authorization'] = "Basic #{self.basic_auth}"
          req.body                     = data.to_json
        end
      end

      nil
    end

    # provide content to User & ask for input to accept call
    # Voice::Bandwidth.call_screen(content: String, callback_url: String)
    # (req) content:      (String)
    # (req) callback_url: (String)
    def self.call_screen(args = {})
      return self.hangup if args.dig(:content).blank? || args.dig(:callback_url).blank?

      self.xml_response_wrap [
        "<Gather gatherUrl=\"#{args[:callback_url]}\" firstDigitTimeout=\"10\" repeatCount=\"3\" maxDigits=\"1\">",
        self.xml_speak("#{args[:content]} Press any key to accept. Press star to send to voicemail."),
        '</Gather>'
      ]
    end

    # transfer a call
    # Voice::Bandwidth.call_transfer
    # (req) from_phone:     (String)
    # (req) to_phones:      (Array)
    # (req) answer_url:     (String)
    # (req) complete_url:   (String)
    # (req) disconnect_url: (string)
    def call_transfer(args = {})
      from_phone    = args.dig(:from_phone).to_s
      to_phones     = args.dig(:to_phones)
      answer_url    = args.dig(:answer_url).to_s
      complete_url  = args.dig(:complete_url).to_s
      disconnect_url = args.dig(:disconnect_url).to_s

      return self.hangup if from_phone.blank? || !to_phones.is_a?(Array) || answer_url.blank? || complete_url.blank? || disconnect_url.blank?

      transfer_xml = ["<Transfer transferCallerId=\"+1#{from_phone}\" callTimeout=\"#{args.dig(:ring_duration).to_i || 20}\" transferCompleteUrl=\"#{complete_url}\">"]

      to_phones.each do |to_phone|
        transfer_xml << "<PhoneNumber transferAnswerUrl=\"#{answer_url}\" transferDisconnectUrl=\"#{disconnect_url}\">+1#{to_phone}</PhoneNumber>"
      end

      transfer_xml << '</Transfer>'

      self.xml_response_wrap transfer_xml
    end

    # delete a recording saved in Cloudinary
    # Voice::Bandwidth.delete_rvm(client: Client, media_url: String)
    # (req) client:    (Client)
    # (req) media_url: (String)
    def self.delete_rvm(args = {})
      return false unless args.dig(:client).is_a?(Client) && args.dig(:media_url).present?

      if (client_attachment = args[:client].client_attachments.find_by(image: args[:media_url][args[:media_url].index('/video/') + 1..]))
        client_attachment.destroy
      end

      true
    end

    # hangup a call
    # Voice::Bandwidth.hangup
    # (opt) call_id:      (String)
    # (opt) content:      (String)
    # (opt) redirect_url: (String)
    def self.hangup(args = {})
      if args.dig(:call_id).to_s.present? && args.dig(:redirect_url).to_s.present?
        self.call_redirect(call_id: args[:call_id].to_s, redirect_url: args[:redirect_url].to_s)
        '<Response></Response>'
      else
        self.xml_response_wrap [
          args.dig(:content).present? ? self.xml_speak(args[:content].to_s) : '',
          '<Hangup/>'
        ]
      end
    end

    # receive a call
    # Voice::Bandwidth.params_parse(params)
    def self.params_parse(args = {})
      sanitized_params = args.permit(:accountId, :applicationId, :callId, :callback_source, :client_phone, :digits, :endTime, :eventTime, :eventType, :from, :mediaUrl, :parent_call_id, :parent_from_phone, :startTime, :to, transcription: %i[completeTime id status url])
      {
        account_id:         sanitized_params.dig(:accountId).to_s,
        answered_by:        nil,                                     # Twilio parameter
        application_id:     sanitized_params.dig(:applicationId).to_s,
        call_duration:      self.call_duration(sanitized_params.dig(:startTime), (sanitized_params.dig(:endTime) || sanitized_params.dig(:eventTime))),
        call_id:            sanitized_params.dig(:callId).to_s,
        call_status:        'initiated',                             # ['busy', 'canceled', 'completed', 'failed', 'initiated', no-answer']
        called:             sanitized_params.dig(:from).to_s.clean_phone,
        callback_source:    sanitized_params.dig(:callback_source).to_s,
        called_via:         nil,
        number_pressed:     sanitized_params.dig(:digits).to_s,
        event_type:         sanitized_params.dig(:eventType).to_s,
        forwarded_from:     nil,
        from_city:          '',                                      # Twilio parameter
        from_phone:         sanitized_params.dig(:from).to_s.clean_phone,
        from_state:         '',                                      # Twilio parameter
        from_zip:           '',                                      # Twilio parameter
        parent_call_id:     sanitized_params.dig(:parent_call_id).to_s,
        parent_from_phone:  sanitized_params.dig(:parent_from_phone).to_s.clean_phone,
        phone_vendor:       'bandwidth',
        recording_url:      sanitized_params.dig(:mediaUrl).to_s,
        to_phone:           sanitized_params.dig(:to).to_s.clean_phone,
        client_phone:       sanitized_params.dig(:client_phone).to_s.clean_phone,
        transcription_text: sanitized_params.dig(:transcription, :url).to_s,
        user_call_status:   'initiated'
      }
    end

    # play a recording to caller and end the call
    # Voice::Bandwidth.play(String)
    def self.play(recording_url)
      self.xml_response_wrap [
        "<PlayAudio>#{recording_url}</PlayAudio>",
        '<Pause duration="1" />',
        '<Hangup/>'
      ]
    end

    # play a recording to caller and wait for voicemail
    # Voice::Bandwidth.play_and_voicemail(recording_url: String, transcribe_url: String)
    # (req) recording_url:  (String)
    # (req) transcribe_url: (String)
    def self.play_and_voicemail(args = {})
      return self.hangup if args.dig(:recording_url).blank? || args.dig(:transcribe_url).blank?

      self.xml_response_wrap [
        "<PlayAudio>#{args[:recording_url]}</PlayAudio>",
        '<Pause duration="1" />',
        '<PlayAudio>https://media.chiirp.com/video/upload/v1645564095/samples/beep.mp3</PlayAudio>',
        self.xml_voicemail(args[:transcribe_url].to_s)
      ]
    end

    # receive recording complete JSON and save recording to Cloudinary
    # Voice::Bandwidth.recording_complete(params)
    def self.recording_complete(args = {})
      {
        success:            true,
        from_phone:         args.dig(:from).to_s.clean_phone,
        to_phone:           args.dig(:to).to_s.clean_phone,
        voice_recording_id: args.dig(:vr_id).to_i,
        recording_sid:      args.dig(:recordingId).to_s,
        recording_url:      args.dig(:mediaUrl).to_s,
        phone_vendor:       'bandwidth',
        response:           ''
      }
    end

    # start a recording
    # Voice::Bandwidth.recording_start(params)
    def self.recording_start(args = {})
      save_recording_url = args.dig(:save_recording_url).to_s

      if save_recording_url.present?
        self.xml_response_wrap [
          '<Pause duration="1" />',
          self.xml_speak('Please record your message. When you are finished recording press the pound key or hang up.'),
          '<Pause duration="1" />',
          '<PlayAudio>https://media.chiirp.com/video/upload/v1645564095/samples/beep.mp3</PlayAudio>',
          "<Record recordingAvailableUrl=\"#{save_recording_url}\" maxDuration=\"3600\"/>"
        ]
      else
        self.xml_response_wrap [
          self.xml_speak('Your call can not be completed as dialed.')
        ]
      end
    end

    # transfer the voice recording from Bandwidth to Cloudinary
    # Voice::Bandwidth.recording_transfer(client: Client, recording_url: String)
    # (req) client:        (Client)
    # (req) recording_url: (String)
    def self.recording_transfer(args = {})
      recording_url = ''

      return recording_url unless args.dig(:client).is_a?(Client) && args.dig(:recording_url).present?

      filename = self.get_media_filename(args[:recording_url])

      result = Faraday.get(args[:recording_url]) do |req|
        req.headers['Authorization'] = "Basic #{self.basic_auth}"
        req.headers['Content-Type']  = 'application/json; charset=utf-8'
      end

      return recording_url unless result.success?

      f = File.open(filename, 'wb')
      f.puts(result.body)
      f.close

      return recording_url unless File.exist?(filename)

      begin
        client_attachment = args[:client].client_attachments.create!(remote_image_url: filename)

        recording_url = client_attachment&.image&.url(resource_type: client_attachment&.image&.resource_type, secure: true)
        retries = 0

        while recording_url.nil? && retries < 10
          retries += 1
          sleep ProcessError::Backoff.full_jitter(retries:)
          client_attachment&.reload
          recording_url = client_attachment&.image&.url(resource_type: client_attachment&.image&.resource_type, secure: true)
        end
      rescue StandardError => e
        e.set_backtrace(BC.new.clean(caller))

        Appsignal.report_error(e) do |transaction|
          # Only needed if it needs to be different or there's no active transaction from which to inherit it
          Appsignal.set_action('Voice::Bandwidth.recording_transfer')

          # Only needed if you want to set different arguments or there's no active transaction from which to inherit it
          Appsignal.add_params(args)

          Appsignal.set_tags(
            error_level: 'info',
            error_code:  0
          )
          Appsignal.add_custom_data(
            e_exception:    e.exception,
            e_full_message: e.full_message,
            e_message:      e.message,
            e_methods:      e.public_methods.inspect,
            recording_url:,
            result:,
            filename:,
            file:           __FILE__,
            line:           __LINE__
          )
        end
      end

      recording_url.presence || ''
    end

    # say "content" to caller
    # render xml: Voice::Bandwidth.say
    # (opt) call_id:              (String)
    # (opt) contact_complete_url: (String)
    # (opt) content:              (String)
    # (opt) user_complete_url:    (String)
    def self.say(args = {})
      if args.dig(:call_id).to_s.present? && args.dig(:contact_complete_url).to_s.present? && args.dig(:user_complete_url).to_s.present?
        self.call_bridge(args)
      else
        self.xml_response_wrap [
          self.xml_speak(args.dig(:content).to_s)
        ]
      end
    end

    # send caller to voicemail
    # Voice::Bandwidth.send_to_voicemail(transcribe_url: String)
    # (req) transcribe_url: (String)
    # (opt) content:        (String)
    def self.send_to_voicemail(args = {})
      return self.hangup if args.dig(:transcribe_url).blank?

      self.xml_response_wrap [
        args.dig(:content).present? ? self.xml_speak(args[:content].to_s) : '',
        self.xml_voicemail(args[:transcribe_url].to_s)
      ]
    end

    # process received transcription text
    # Voice::Bandwidth.transcription_text(transcription_text_url: String)
    # (req) transcription_text_url: (String)
    def self.transcription_text(args = {})
      return '' if args.dig(:transcription_text_url).blank?

      result = Faraday.get(args[:transcription_text_url]) do |req|
        req.headers['Authorization'] = "Basic #{self.basic_auth}"
        req.headers['Content-Type']  = 'application/json; charset=utf-8'
      end

      if result.success?
        JSON.parse(result.body).dig('transcripts')[0].dig('text').to_s
      else
        ''
      end
    end

    def self.account_id
      Rails.application.credentials[:bandwidth][:account_id]
    end

    def self.application_id
      ENV.fetch('BANDWIDTH_VOICE_APPLICATION_ID', nil)
    end

    def self.base_voice_url
      "https://voice.bandwidth.com/api/v2/accounts/#{self.account_id}"
    end

    def self.basic_auth
      Base64.urlsafe_encode64("#{Rails.application.credentials[:bandwidth][:user_name]}:#{Rails.application.credentials[:bandwidth][:password]}").strip
    end

    # Takes a full media url from Bandwidth and extracts the filename
    # @param media_url [String] The full media url
    # @returns [String] The media file name
    def self.get_media_filename(media_url)
      media_url.split('/')[-1]
    end

    def self.language
      'en_US'
    end

    def self.url_host
      I18n.with_locale('chiirp') { I18n.t("tenant.#{Rails.env}.app_host") }
    end

    def self.url_protocol
      I18n.with_locale('chiirp') { I18n.t('tenant.app_protocol') }
    end

    def self.voice
      'julie'
    end

    def self.xml_response_wrap(xml_lines)
      response = '<Response>'
      xml_lines.each { |line| response += line if line.present? }
      response += '</Response>'
    end

    def self.xml_speak(content)
      "<SpeakSentence locale=\"#{self.language}\" voice=\"#{self.voice}\">#{content}</SpeakSentence>"
    end

    def self.xml_voicemail(callback_url)
      "<Record maxDuration=\"60\" transcribe=\"true\" fileFormat=\"mp3\" recordCompleteUrl=\"#{callback_url}\" transcriptionAvailableUrl=\"#{callback_url}\"/>"
    end
  end
end
