# frozen_string_literal: true

class Contacts::ExportJob < ApplicationJob
  queue_as :default

  def initialize(**args)
    super

    @process = (args.dig(:process).presence || 'contact_export').to_s
  end

  # perform the ActiveJob
  #   (req) user_id: (Integer) User ID to send notification to
  #   (req) data.contacts: (Array<Integer>) Contact IDs to export
  #   (req) fields: (Array<String>) Fields to include in the export
  def perform(**args)
    standard_fields = args[:fields].filter { |field| field.start_with?('standard|') }.map { |key| key.gsub('standard|', '') }
    phone_fields = args[:fields].filter { |field| field.start_with?('phones|') }.map { |key| key.gsub('phones|', '') }
    custom_fields = args[:fields].filter { |field| field.start_with?('custom_fields|') }.map { |key| key.gsub('custom_fields|', '') }
    integrations_fields = args[:fields].filter { |field| field.start_with?('integration|') }.map { |key| key.gsub('integration|', '') }

    csv = Contact.where(id: args.dig(:data, :contacts)).includes(:contact_phones).as_csv(standard_fields:, phone_fields:, custom_fields:, integrations_fields:)
    UserMailer.with(user_id: args[:user_id], csv:).contacts_export_notification.deliver_now
  end
end
