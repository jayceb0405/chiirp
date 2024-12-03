# frozen_string_literal: true

# app/presenters/clients/voice_recordings/presenter.rb
module Clients
  module VoiceRecordings
    class Presenter
      attr_accessor :voice_recording
      attr_reader   :client

      def initialize(args = {})
        self.client = args.dig(:client)
      end

      def client=(client)
        @client = case client
                  when Client
                    client
                  when Integer
                    Client.find_by(id: client)
                  else
                    Client.new
                  end

        @voice_recording            = nil
        @voice_recordings_delivered = nil
        @voice_recordings_failed    = nil
      end

      def ok_to_create_new_voice_recording
        self.voice_recordings.count < self.client.max_voice_recordings
      end

      def phone_numbers_using_voice_recording_as_announcement
        @voice_recording.announcement_recordings
      end

      def phone_numbers_using_voice_recording_as_greeting
        @voice_recording.vm_greeting_recordings
      end

      def voice_recordings
        self.client.voice_recordings.order(:recording_name)
      end

      def voice_recordings_delivered
        @voice_recordings_delivered ||= self.voice_recording.url.present? ? Messages::Message.voice_recordings_delivered(self.voice_recording.id).count.to_i : 0
      end

      def voice_recordings_delivery_rate
        self.voice_recordings_sent.positive? ? (self.voice_recordings_delivered.to_f / self.voice_recordings_sent).round(1) : 0.0
      end

      def voice_recordings_failed
        @voice_recordings_failed ||= self.voice_recording.url.present? ? Messages::Message.voice_recordings_failed(self.voice_recording.id).count.to_i : 0
      end

      def voice_recordings_sent
        self.voice_recordings_delivered + self.voice_recordings_failed
      end

      def voice_recording_url
        if @voice_recording.audio_file.attached?
          "#{Cloudinary::Utils.cloudinary_url(@voice_recording.audio_file.key, resource_type: 'video', secure: true)}.mp3"
        else
          "#{self.voice_recording.url.gsub('.wav', '')}#{self.voice_recording.url.present? && self.voice_recording.url.exclude?('.mp3') ? '.mp3' : ''}"
        end
      end
    end
  end
end
