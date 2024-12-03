# frozen_string_literal: true

# app/models/contact_phone.rb
class ContactPhone < ApplicationRecord
  belongs_to :contact

  # rubocop:disable Rails/UniqueValidationWithoutIndex, Rails/I18nLocaleTexts
  validates  :phone,
             presence:   true,
             # length: { is: 10, message: "must be 10 characters" },
             uniqueness: { scope: :contact, message: 'already exists' }
  # rubocop:enable Rails/UniqueValidationWithoutIndex, Rails/I18nLocaleTexts
  validates  :label,
             presence: true

  before_validation    :before_validation_actions
  before_save          :before_save_actions
  before_destroy       :before_destroy_actions
  after_commit         :update_client_labels

  scope :client_labels, ->(client_id) {
    joins(:contact, contact: :client)
      .where(clients: { id: client_id })
      .distinct
      .pluck(:label) | DEFAULT_LABELS
  }
  scope :contact_labels, ->(contact_id) {
    where(contact_id:)
      .distinct
      .pluck(:label)
  }
  scope :contact_labels_for_select, ->(contact_id) {
    contact_labels(contact_id)
      .map { |label| [label.capitalize, label] }
      .sort_by { |label| label[0] }
  }
  scope :contact_phones, ->(contact_id) {
    where(contact_id:)
      .pluck(:label, :phone)
  }
  scope :contact_phones_for_select, ->(contact_id) {
    contact_phones(contact_id)
      .map { |phone| ["#{phone[0].capitalize} (#{ActionController::Base.helpers.number_to_phone(phone[1])})", phone[1]] }
  }
  scope :find_by_client_and_phone, ->(client_id, phone) {
    joins(:contact, contact: :client)
      .where(clients: { id: client_id })
      .where(phone:)
  }

  DEFAULT_LABELS = %w[mobile home office fax other].freeze

  private

  def before_destroy_actions
    return unless self.primary? && (contact_phone = self.contact.contact_phones.where.not(id: self.id))

    contact_phone.update(primary: true)
  end

  def before_save_actions
    if self.primary?

      if self.new_record?
        self.contact.contact_phones.reject { |contact_phone| contact_phone.phone == self.phone }.each do |cf|
          cf.primary = false
        end
      else
        # rubocop:disable Rails/SkipsModelValidations
        self.contact.contact_phones.where(primary: true).where.not(id: self.id).update_all(primary: false)
        # rubocop:enable Rails/SkipsModelValidations
      end
    end

    self.label = self.label.strip.downcase.tr('_', '-')
  end

  def before_validation_actions
    self.phone = self.phone.clean_phone(self.contact.client.primary_area_code) unless self.phone.nil?
    self.label = 'other' if self.label.to_s.blank?
    self.label = self.label.strip.gsub(%r{[^\w$()<>?!+~./: &-]}, '')

    return if self.primary?

    self.primary = true if (self.new_record? && self.contact.contact_phones&.find(&:primary).blank?) || (!self.new_record? && self.contact.contact_phones.where.not(id: self.id).where(primary: true).blank?)
  end

  def update_client_labels
    return if self.label_previously_was == self.label

    if saved_change_to_id?
      # this record was created
      Clients::UpdateClientLabelsJob.perform_later(client_id: self.contact.client_id, new_label: self.label) unless DelayedJob.where(process: 'update_client_labels').where('data @> ?', { new_label: self.label }.to_json).exists?(['data @> ?', { client_id: self.contact.client_id }.to_json])
    else
      Clients::UpdateClientLabelsJob.perform_later(client_id: self.contact.client_id) unless DelayedJob.where(process: 'update_client_labels').exists?(['data @> ?', { client_id: self.contact.client_id }.to_json])
    end
  end
end
