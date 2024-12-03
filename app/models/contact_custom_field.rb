# frozen_string_literal: true

# app/models/contact_custom_field.rb
class ContactCustomField < ApplicationRecord
  belongs_to :contact
  belongs_to :client_custom_field

  before_validation :before_validation_actions

  scope :contacts_updated, ->(client_custom_field_id, from_date, to_date) {
    Contact.joins(:contact_custom_fields)
           .where(client_custom_field_id:)
           .where(updated_at: [from_date..to_date])
           .group(:id)
  }

  private

  def after_create_commit_actions
    super

    return if self.var_value.to_s.empty? || self.var_value.to_i.zero?

    send_to_zapier
  end

  def after_update_commit_actions
    super

    return if self.previous_changes.delete_if { |k, _v| k == 'updated_at' }.blank?

    send_to_zapier
  end

  def before_validation_actions
    self.var_value = Chronic.parse(self.var_value.to_s)&.utc&.iso8601.to_s if self.var_value_changed? && self.client_custom_field.var_type == 'date'
  end

  def send_to_zapier
    self.contact.send_to_zapier(action: 'receive_updated_contact')
  end
end
