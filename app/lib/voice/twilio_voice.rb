# frozen_string_literal: true

# app/lib/voice/twilio_voice.rb
module Voice
  # process API calls to Twilio to support voice processing
  module TwilioVoice
    # place a call
    # Voice::TwilioVoice.call(from_phone: String, to_phone: String, callback_url: String)
    def self.call(args = {})
      from_phone        = args.dig(:from_phone).to_s.clean_phone
      to_phone          = args.dig(:to_phone).to_s.clean_phone
      callback_url      = args.dig(:callback_url).to_s
      machine_detection = args.dig(:machine_detection).to_bool
      response          = { success: false, error_code: '', error_message: '' }

      if from_phone.present? && to_phone.present? && callback_url.present?

        begin
          retries ||= 0
          twilioclient = self.twilio_client

          result = twilioclient.calls.create(
            to:                     "+1#{to_phone}",
            from:                   "+1#{from_phone}",
            url:                    callback_url,
            status_callback_method: 'POST',
            status_callback:        callback_url,
            status_callback_event:  %w[initiated completed],
            machine_detection:      (machine_detection ? 'Enable' : '')
          )

          response[:success] = true
        rescue Twilio::REST::TwilioError => e
          retry if e.message.downcase.include?('temporary failure') && (retries += 1) < 3

          # response[:error_code]    = e.code
          response[:error_message] = e.message

          ProcessError::Report.send(
            error_message: "Voice::Call: #{e.message}",
            variables:     {
              args:      args.inspect,
              result:    (defined?(result) ? result.inspect : nil),
              response:  response.inspect,
              e:         e.inspect,
              # e_code: e.code.inspect,
              e_methods: e.methods.inspect,
              e_message: e.message.inspect,
              file:      __FILE__,
              line:      __LINE__
            }
          )
        rescue StandardError => e
          response[:error_code]    = ''
          response[:error_message] = e.message

          ProcessError::Report.send(
            error_message: "Voice::Call: #{e.message}",
            variables:     {
              args:     args.inspect,
              result:   (defined?(result) ? result.inspect : nil),
              response: response.inspect,
              e:        e.inspect,
              file:     __FILE__,
              line:     __LINE__
            }
          )
        end
      else
        response[:error_message] += 'Unknown origination phone number. ' if from_phone.empty?
        response[:error_message] += 'Unknown destination phone number. ' if to_phone.empty?
        response[:error_message] += 'Unknown processor. ' if callback_url.empty?
      end

      response
    end

    # connect incoming call to User
    # Voice::TwilioVoice.call_incoming_connect(user_array: Array, voicemail_url: String, complete_url: String)
    # (req) complete_url:     (String)
    # (req) user_array        (Array)
    # (req) voicemail_url:    (String)
    # (opt) announcement_url: (String)
    def self.call_incoming_connect(args = {})
      return '' unless args.dig(:user_array).is_a?(Array) && args.dig(:voicemail_url).present? && args.dig(:complete_url).present?

      ring_duration = [args[:user_array].map { |u| u.dig(:ring_duration) }.compact_blank.min.to_i, 20].max
      response      = self.twiml_client

      response.play(loop: 1, url: args[:announcement_url].to_s) if args.dig(:announcement_url).present?
      response.dial(timeout: ring_duration, action: args[:complete_url].to_s) do |dial|
        args[:user_array].each do |u|
          dial.number(u[:phone], url: u[:action_url])
        end
      end

      response.to_s
    end

    # connect incoming call to User with intervention
    # Voice::TwilioVoice.call_incoming_connect_with_intervention(to_phone: String, screencall_url: String, voicemail_url: String)
    def self.call_incoming_connect_with_intervention(args = {})
      response = self.twiml_client
      response.dial(action: args.dig(:voicemail_url).to_s, method: 'POST') do |dial|
        dial.number("+1#{args.dig(:to_phone)}", timeout: (args.dig(:ring_duration) || 20).to_i, action: args.dig(:screencall_url).to_s)
      end

      response.to_s
    end

    # connect a previously initiated outgoing call with another phone number
    # Voice::TwilioVoice.call_outgoing_connect(to_phone: String, content: String)
    def self.call_outgoing_connect(args = {})
      response = self.twiml_client
      response.pause(length: 1)
      response.say(voice: self.voice, language: self.language, message: args.dig(:content).to_s)
      response.dial(number: "+1#{args.dig(:to_phone)}", timeout: (args.dig(:ring_duration) || 20).to_i)

      response.to_s
    end

    # provide content to User & ask for input to accept call
    # Voice::TwilioVoice.call_screen(content: String, callback_url: String)
    def self.call_screen(args = {})
      response = self.twiml_client

      response.gather(action: args.dig(:callback_url).to_s, method: 'POST', timeout: 5, numDigits: '1') do |gather|
        gather.say(voice: self.voice, language: self.language, message: "#{args.dig(:content)} Press any key to accept. Press star to send to voicemail.")
      end

      # will return status no-answer since this is a Number callback
      response.say(voice: self.voice, language: self.language, message: 'Sorry, I didn\'t get your response.')
      response.hangup

      response.to_s
    end

    # place a call
    # Voice::TwilioVoice.call_update(call_id: String, redirect_url: String)
    def self.call_update(args = {})
      call_id      = args.dig(:call_id).to_s
      redirect_url = args.dig(:redirect_url).to_s
      xml          = args.dig(:xml).to_s
      response     = { success: false, error_code: '', error_message: '' }

      if call_id.blank?
        response[:error_message] = 'Call ID is required.'
        return response
      elsif redirect_url.blank? && xml.blank?
        response[:error_message] = 'Redirect URL or XML is required.'
        return response
      end

      begin
        retries ||= 0
        twilioclient = self.twilio_client

        result = if redirect_url.present?
                   twilioclient.calls(call_id).update(url: redirect_url)
                 else
                   twilioclient.calls(call_id).update(twiml: xml)
                 end

        response[:success] = true
      rescue Twilio::REST::TwilioError => e
        retry if e.message.downcase.include?('temporary failure') && (retries += 1) < 3

        if e.message.include?('21220')
          # party hung up
          JsonLog.info 'Voice::TwilioVoice.call_update', { error_code: e.code, error_message: e.message }
        else
          response[:error_code]    = e.code
          response[:error_message] = e.message

          ProcessError::Report.send(
            error_message: "Voice::CallUpdate: #{e.message}",
            variables:     {
              args:      args.inspect,
              result:    (defined?(result) ? result.inspect : nil),
              response:  response.inspect,
              e:         e.inspect,
              e_code:    e.code.inspect,
              e_methods: e.methods.inspect,
              e_message: e.message.inspect
            },
            file:          __FILE__,
            line:          __LINE__
          )
        end
      rescue StandardError => e
        response[:error_code]    = ''
        response[:error_message] = e.message

        ProcessError::Report.send(
          error_message: "Voice::Call: #{e.message}",
          variables:     {
            args:     args.inspect,
            result:   (defined?(result) ? result.inspect : nil),
            response: response.inspect,
            e:        e.inspect
          },
          file:          __FILE__,
          line:          __LINE__
        )
      end

      response
    end

    # delete a recording saved by Twilio
    # Voice::TwilioVoice.delete_rvm(media_sid: String)
    def self.delete_rvm(args = {})
      media_sid = args.dig(:media_sid).to_s
      response  = false

      if media_sid.present?
        twilioclient = self.twilio_client

        begin
          response = twilioclient.recordings(media_sid).delete
        rescue StandardError => e
          # something happened
          ProcessError::Report.send(
            error_message: "Voice::DeleteRVM: #{e.message}",
            variables:     {
              args:      args.inspect,
              media_sid: media_sid.inspect,
              response:  response.inspect,
              e:         e.inspect,
              file:      __FILE__,
              line:      __LINE__
            }
          )
        end
      end

      response
    end

    # get child calls from Twilio
    # Voice::TwilioVoice.get_child_calls(parent_sid: String)
    def self.get_child_calls(args = {})
      parent_sid    = args.dig(:parent_sid).to_s
      twilio_client = self.twilio_client
      response      = []

      if parent_sid.present?
        begin
          retries ||= 0
          response  = []

          twilio_client.calls.list(parent_call_sid: parent_sid).each do |child|
            response << {
              message_sid:   child.sid.to_s,
              price:         child.price.to_s.to_d.abs,
              status:        child.status.to_s,
              call_duration: child.duration.to_i,
              direction:     child.direction,
              from_phone:    child.from,
              to_phone:      child.to,
              start_time:    child.start_time,
              end_time:      child.end_time
            }
          end
        rescue Twilio::REST::TwilioError => e
          retry if e.message.casecmp?('execution expired') && (retries += 1) < 3

          ProcessError::Report.send(
            error_message: "SMS::GetChildCalls: #{e.message}",
            variables:     {
              args:                                         args.inspect,
              e:                                            e.inspect,
              response:                                     response.inspect,
              retries:                                      retries.inspect,
              twilio_client_http_client_last_response_body: defined?(twilio_client.http_client.last_response.body) ? twilio_client.http_client.last_response.body.inspect : 'Undefined',
              file:                                         __FILE__,
              line:                                         __LINE__
            }
          )
        rescue StandardError => e
          ProcessError::Report.send(
            error_message: "SMS::GetChildCalls: #{e.message}",
            variables:     {
              args:                                         args.inspect,
              e:                                            e.inspect,
              response:                                     response.inspect,
              retries:                                      retries.inspect,
              twilio_client_http_client_last_response_body: defined?(twilio_client.http_client.last_response.body) ? twilio_client.http_client.last_response.body.inspect : 'Undefined',
              file:                                         __FILE__,
              line:                                         __LINE__
            }
          )
        end
      end

      response
    end

    # hangup a call
    # Voice::TwilioVoice.hangup
    def self.hangup(args = {})
      response = self.twiml_client
      response.say(voice: self.voice, language: self.language, message: args[:content]) if args.dig(:content).to_s.present?
      response.hangup

      response.to_s
    end

    # receive a call
    # Voice::TwilioVoice.params_parse(params)
    def self.params_parse(args = {})
      {
        account_id:         args.dig(:AccountSid).to_s,
        answered_by:        args.dig(:AnsweredBy).to_s.downcase, # ['human', 'unknown']
        application_id:     nil, # Bandwidth parameter
        call_duration:      (args.dig(:CallDuration) || args.dig(:DialCallDuration)).to_i,
        call_id:            args.dig(:CallSid).to_s,
        call_status:        args.dig(:CallStatus).to_s, # ['busy', 'canceled', 'completed', 'failed', 'initiated', no-answer']
        called:             args.dig(:Called).to_s.clean_phone,
        callback_source:    args.dig(:CallbackSource).to_s.downcase,
        called_via:         args.dig(:CalledVia).to_s.clean_phone,
        number_pressed:     args.dig(:Digits).to_s,
        event_type:         nil,                                      # Bandwidth parameter
        forwarded_from:     args.dig(:ForwardedFrom).to_s.clean_phone,
        from_city:          args.dig(:FromCity).to_s,
        from_phone:         args.dig(:From).to_s.clean_phone,
        from_state:         args.dig(:FromState).to_s,
        from_zip:           args.dig(:FromZip).to_s,
        parent_call_id:     args.dig(:ParentCallSid).to_s,
        parent_from_phone:  nil,                                      # Bandwidth parameter
        phone_vendor:       'twilio',
        recording_url:      args.dig(:RecordingUrl).to_s,
        to_phone:           args.dig(:To).to_s.clean_phone,
        transcription_text: args.dig(:TranscriptionText).to_s,
        user_call_status:   args.dig(:DialCallStatus).to_s
      }
    end

    # play a recording to caller and end the call
    # render xml: Voice::TwilioVoice.play(String)
    def self.play(recording_url)
      response = self.twiml_client
      response.play(loop: 1, url: recording_url)

      response.to_s
    end

    # play a recording to caller and wait for voicemail
    # render xml: Voice::TwilioVoice.play_and_voicemail(recording_url: String, transcribe_url: String)
    def self.play_and_voicemail(args = {})
      response = self.twiml_client
      response.play(loop: 1, url: args.dig(:recording_url).to_s)
      response.record(finish_on_key: '*', transcribe: true, max_length: '20', transcribe_callback: args.dig(:transcribe_url).to_s, method: 'POST')
      response.say(voice: self.voice, language: self.language, message: 'I did not receive a recording.')

      response.to_s
    end

    # receive recording complete
    # Voice::TwilioVoice.recording_complete(params)
    def self.recording_complete(args = {})
      response = self.twiml_client

      {
        success:            true,
        from_phone:         args.dig(:From).to_s.clean_phone,
        to_phone:           args.dig(:To).to_s.clean_phone,
        voice_recording_id: args.dig(:vr_id).to_i,
        recording_sid:      args.dig(:RecordingSid).to_s,
        recording_url:      args.dig(:RecordingUrl).to_s,
        phone_vendor:       'twilio',
        response:           response.hangup.to_s
      }
    end

    # start a recording
    # Voice::TwilioVoice.recording_start(params)
    def self.recording_start(args = {})
      save_recording_url = args.dig(:save_recording_url).to_s
      response           = self.twiml_client

      if save_recording_url.present?
        response.pause(length: 1)
        response.say(voice: self.voice, loop: '1', language: self.language, message: 'Please record your message. When you are finished recording press the pound key or hang up.')
        response.record(timeout: 0, transcribe: false, finishOnKey: '#', maxLength: 3600, action: save_recording_url)
      else
        response.say(voice: self.voice, loop: '2', language: self.language, message: 'Your call can not be completed as dialed.    ')
      end

      response.to_s
    end

    # transfer the voice recording from Twilio to Cloudinary
    # Twilio recordings remain at Twilio for now
    # Voice::TwilioVoice.recording_transfer(client: Client, recording_url: String)
    def self.recording_transfer(args = {})
      "#{args.dig(:recording_url)}.mp3"
    end

    # say "content" to caller and end the call
    # render xml: Voice::TwilioVoice.say(content: String)
    def self.say(args = {})
      response = self.twiml_client
      response.say(voice: self.voice, language: self.language, message: args.dig(:content).to_s)

      response.to_s
    end

    # respond to caller with option to leave voicemail
    # Voice::TwilioVoice.send_to_voicemail(transcribe_url: String)
    # (req) transcribe_url:      (String)
    # (opt) content:             (String)
    # (opt) voice_recording_url: (String)
    def self.send_to_voicemail(args = {})
      response = self.twiml_client

      if args.dig(:voice_recording_url).present?
        response.play(loop: 1, url: args[:voice_recording_url])
      else
        response.say(voice: self.voice, language: self.language, message: "#{args.dig(:content).present? ? args[:content] : 'No one is available to take your call.'} Please leave a message after the beep. Press star to complete or simply hang up.")
      end

      response.record(finish_on_key: '*', transcribe: true, max_length: '60', transcribe_callback: args.dig(:transcribe_url), method: 'POST')
      response.say(voice: self.voice, language: self.language, message: 'I did not receive a recording.')

      response.to_s
    end

    # process received transcription text
    # Voice::TwilioVoice.transcription_text(transcription_text_url: String)
    def self.transcription_text(args = {})
      args.dig(:transcription_text_url).to_s
    end

    def self.language
      'en-US'
    end

    def self.twilio_client
      Twilio::REST::Client.new(
        Rails.application.credentials[:twilio][:sid],
        Rails.application.credentials[:twilio][:auth]
      )
    end

    def self.twiml_client
      Twilio::TwiML::VoiceResponse.new
    end

    def self.url_host
      I18n.with_locale('chiirp') { I18n.t("tenant.#{Rails.env}.app_host") }
    end

    def self.url_protocol
      I18n.with_locale('chiirp') { I18n.t('tenant.app_protocol') }
    end

    def self.voice
      'alice'
    end
  end
end
