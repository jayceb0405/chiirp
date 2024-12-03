# frozen_string_literal: true

# app/models/voice_recording.rb
class VoiceRecording < ApplicationRecord
  has_one_attached :audio_file, dependent: :purge_later

  belongs_to :client

  has_many :messages,                dependent: :nullify, class_name: '::Messages::Message'
  has_many :vm_greeting_recordings,  dependent: :nullify, foreign_key: :vm_greeting_recording_id, class_name: :Twnumber, inverse_of: :vm_greeting_recording
  has_many :announcement_recordings, dependent: :nullify, foreign_key: :announcement_recording_id, class_name: :Twnumber, inverse_of: :announcement_recording

  validate       :count_is_approved, on: [:create]
  validates      :recording_name, presence: true, length: { minimum: 5 }
  before_destroy :before_destroy_actions

  scope :by_client, ->(client_id) {
    where(client_id:)
  }
  scope :by_tenant, ->(tenant = 'chiirp') {
    joins(:client)
      .where(clients: { tenant: })
  }

  def url
    self.read_attribute(:url).presence || (self.audio_file.attached? ? "#{Cloudinary::Utils.cloudinary_url(self.audio_file.key, resource_type: 'video', secure: true)}.mp3" : '')
  end

  private

  def after_destroy_commit_actions
    super

    Triggeraction.for_client_and_action_type(self.client.id, 150).find_each do |triggeraction|
      triggeraction.campaign.update(analyzed: triggeraction.campaign.analyze!.empty?) if triggeraction.campaign_id == self.id
    end
  end

  def before_destroy_actions
    Voice::Router.delete_rvm(client: self.client, media_sid: self.sid, media_url: self.url)
  end

  # confirm that count is less than Client.max_voice_recordings setting
  # validate :count_is_approved
  def count_is_approved
    errors.add(:base, "Maximum Voice Recordings for #{self.client.name} has been met.") unless self.client.voice_recordings.count < self.client.max_voice_recordings.to_i
  end
end
