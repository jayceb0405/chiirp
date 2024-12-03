# frozen_string_literal: true

# app/lib/voice/router.rb
module Voice
  # router used to process all calls to both Bandwidth & Twilio
  module Router
    def self.call(args = {})
      # place a call
      # Voice::Router.call(phone_vendor: String, from_phone: String, to_phone: String, callback_url: String)
      case args.dig(:phone_vendor).to_s
      when 'twilio'
        Voice::TwilioVoice.call(args)
      when 'bandwidth'
        Voice::Bandwidth.call(args)
      end
    end

    def self.call_accept_voicemail(args = {})
      # respond to caller with option to leave voicemail
      # Voice::Router.call_accept_voicemail(phone_vendor: String, content: String, voice_recording_url: String, transcribe_url: String)
      case args.dig(:phone_vendor).to_s
      when 'twilio'
        Voice::TwilioVoice.call_accept_voicemail(args)
      when 'bandwidth'
        Voice::Bandwidth.call_accept_voicemail(args)
      end
    end

    def self.call_bridge(args = {})
      # bridge 2 calls together
      # Voice::Router.call_bridge(String)
      # only used by Bandwidth
      Voice::Bandwidth.call_bridge(args)
    end

    def self.call_incoming_connect(args = {})
      # connect incoming call to User
      # Voice::Router.call_incoming_connect(phone_vendor: String, from_phone: String, to_phone: String, callback_url: String)
      case args.dig(:phone_vendor).to_s
      when 'twilio'
        Voice::TwilioVoice.call_incoming_connect(args)
      when 'bandwidth'
        Voice::Bandwidth.call_incoming_connect(args)
      end
    end

    def self.call_incoming_connect_with_intervention(args = {})
      # connect incoming call to User with intervention
      # Voice::Router.call_incoming_connect_with_intervention(phone_vendor: String, to_phone: String, screencall_url: String, voicemail_url: String)
      case args.dig(:phone_vendor).to_s
      when 'twilio'
        Voice::TwilioVoice.call_incoming_connect_with_intervention(args)
      when 'bandwidth'
        Voice::Bandwidth.call_incoming_connect_with_intervention(args)
      end
    end

    def self.call_outgoing_connect(args = {})
      # connect a previously initiated outgoing call with another phone number
      # Voice::Router.call_outgoing_connect(phone_vendor: String, from_phone: String, to_phone: String, content: String, callback_url: String)
      case args.dig(:phone_vendor).to_s
      when 'twilio'
        Voice::TwilioVoice.call_outgoing_connect(args)
      when 'bandwidth'
        Voice::Bandwidth.call_outgoing_connect(args)
      end
    end

    def self.call_screen(args = {})
      # provide content to User & ask for input to accept call
      # Voice::Router.call_screen(phone_vendor: String, content: String, callback_url: String)
      case args.dig(:phone_vendor).to_s
      when 'twilio'
        Voice::TwilioVoice.call_screen(args)
      when 'bandwidth'
        Voice::Bandwidth.call_screen(args)
      end
    end

    def self.delete_rvm(args = {})
      # delete a recording
      # Voice::Router.delete_rvm(client: Client, media_sid: String, media_url: String)
      if args.dig(:media_sid).to_s[0, 2] == 'RE'
        Voice::TwilioVoice.delete_rvm(args)
      else
        Voice::Bandwidth.delete_rvm(args)
      end
    end

    def self.get_child_calls(args = {})
      # get child calls from Twilio
      # Voice::Router.get_child_calls(phone_vendor: String, parent_sid: String)
      case args.dig(:phone_vendor).to_s
      when 'twilio'
        Voice::TwilioVoice.get_child_calls(args)
      when 'bandwidth'
        Voice::Bandwidth.get_child_calls(args)
      end
    end

    def self.hangup(args = {})
      # hangup a call
      # Voice::Router.hangup(phone_vendor: String, content: String)
      case args.dig(:phone_vendor).to_s
      when 'twilio'
        Voice::TwilioVoice.hangup(args)
      when 'bandwidth'
        Voice::Bandwidth.hangup(args)
      end
    end

    def self.params_parse(args = {})
      # receive a call
      # Voice::Router.params_parse(params)
      if args.include?(:AccountSid)
        Voice::TwilioVoice.params_parse(args)
      elsif args.include?(:accountId)
        Voice::Bandwidth.params_parse(args)
      end
    end

    def self.play(phone_vendor, recording_url)
      # play a recording to caller and end the call
      # render xml: Voice::Router.play(phone_vendor (String), recording_url (String))
      case phone_vendor
      when 'twilio'
        Voice::TwilioVoice.play(recording_url)
      when 'bandwidth'
        Voice::Bandwidth.play(recording_url)
      end
    end

    def self.play_and_voicemail(args = {})
      # play a recording to caller and wait for voicemail
      # render xml: Voice::Router.play_and_voicemail(phone_vendor: String, recording_url: String, transcribe_url: String)
      case args.dig(:phone_vendor).to_s
      when 'twilio'
        Voice::TwilioVoice.play_and_voicemail(args)
      when 'bandwidth'
        Voice::Bandwidth.play_and_voicemail(args)
      end
    end

    def self.recording_complete(args = {})
      # receive recording complete JSON
      # Voice::Router.recording_complete(params)
      if args.include?(:AccountSid)
        Voice::TwilioVoice.recording_complete(args)
      elsif args.include?(:accountId)
        Voice::Bandwidth.recording_complete(args)
      end
    end

    def self.recording_start(args = {})
      # start a recording
      # Voice::Router.recording_start(params)
      if args.include?(:AccountSid)
        Voice::TwilioVoice.recording_start(args)
      elsif args.include?(:accountId)
        Voice::Bandwidth.recording_start(args)
      end
    end

    def self.recording_transfer(args = {})
      # transfer the voice recording from Cloudinary
      # Voice::Router.recording_transfer(phone_vendor: String, client: Client, recording_url: String)
      case args.dig(:phone_vendor).to_s
      when 'twilio'
        Voice::TwilioVoice.recording_transfer(args)
      when 'bandwidth'
        Voice::Bandwidth.recording_transfer(args)
      end
    end

    def self.say(args = {})
      # say "content" to caller and end the call
      # render xml: Voice::Router.say(phone_vendor: String, content: String)
      case args.dig(:phone_vendor).to_s
      when 'twilio'
        Voice::TwilioVoice.say(args)
      when 'bandwidth'
        Voice::Bandwidth.say(args)
      end
    end

    def self.send_to_voicemail(args = {})
      # send caller to voicemail
      # Voice::Router.send_to_voicemail(phone_vendor: String, content: String, transcribe_url: String)
      case args.dig(:phone_vendor).to_s
      when 'twilio'
        Voice::TwilioVoice.send_to_voicemail(args)
      when 'bandwidth'
        Voice::Bandwidth.send_to_voicemail(args)
      end
    end

    def self.transcription_text(args = {})
      # get transcription text from phone vendor
      # Voice::Router.transctiption_text(phone_vendor: String, transcription_text_url: String)
      case args.dig(:phone_vendor).to_s
      when 'twilio'
        Voice::TwilioVoice.transcription_text(args)
      when 'bandwidth'
        Voice::Bandwidth.transcription_text(args)
      end
    end
  end
end
