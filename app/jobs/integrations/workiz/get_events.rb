# frozen_string_literal: true

# app/jobs/zapier/send_job.rb
module Integrations
  module Zapier
    class SendJob < ApplicationJob
      # description of this job
      # Integrations::Zapier::SendJob.perform_now()
      # Integrations::Zapier::SendJob.set(wait_until: 1.day.from_now).perform_later()
      # Integrations::Zapier::SendJob.set(wait_until: 1.day.from_now, priority: 0).perform_later(
      def initialize(**args)
        super

        @process = (args.dig(:process).presence || 'zapier_send').to_s
      end

      # perform the ActiveJob
      #   (req) action:                  (String)
      #   (req) contact_id:              (Integer)
      #   (req) user_api_integration_id: (Integer)
      #
      #   (opt) tag_data:                (Hash / default: {})
      def perform(**args)
        super

        return Integrations::Zapier::Base.new.zapier_request unless args.dig(:action).present? &&
                                                                    Integer(args.dig(:contact_id), exception: false).present? && Integer(args.dig(:user_api_integration_id), exception: false).present? &&
                                                                    (user_api_integration = UserApiIntegration.find_by(id: args[:user_api_integration_id].to_i)) && user_api_integration.target.casecmp?('zapier') &&
                                                                    user_api_integration.zapier_subscription_url.present? &&
                                                                    (contact = Contact.find_by(id: args[:contact_id].to_i)) && args.dig(:tag_data).is_a?(Hash) &&
                                                                    contact.client.active? && contact.client.integrations_allowed.include?('zapier')

        Integrations::Zapier::Base.new.zapier_request(
          body:                    zap_data(contact).merge(args.dig(:tag_data).presence || {}),
          url:                     user_api_integration.zapier_subscription_url,
          user_api_integration_id: user_api_integration.id
        )
      end

      private

      def zap_data(contact)
        primary_phone = contact.primary_phone&.phone.to_s
        alt_phone     = contact.contact_phones.find_by(primary: false)&.phone.to_s
        custom_fields = contact.contact_custom_fields.joins(:client_custom_field).pluck('client_custom_fields.var_name', :var_value).map { |x| x.join(':') }.join(',')
        notes         = ActionController::Base.helpers.safe_join(contact.notes.pluck(:note), ', ')
        tags          = ActionController::Base.helpers.safe_join(contact.tags.pluck(:name), ',')

        {
          user_name:             contact.user.fullname.to_s,
          user_id:               contact.user_id.to_s,
          lastname:              contact.lastname.to_s,
          firstname:             contact.firstname.to_s,
          fullname:              contact.fullname.to_s,
          address1:              contact.address1.to_s,
          address2:              contact.address2.to_s,
          city:                  contact.city.to_s,
          state:                 contact.state.to_s,
          zipcode:               contact.zipcode.to_s,
          phone:                 primary_phone,
          alt_phone:,
          phone_was:             primary_phone,
          email:                 contact.email.to_s,
          birthdate:             (contact.birthdate ? contact.birthdate.strftime('%Y/%m/%d') : ''),
          ok2text:               (contact.ok2text.to_i == 1 ? 'yes' : 'no'),
          ok2email:              (contact.ok2email.to_i == 1 ? 'yes' : 'no'),
          ext_ref_id:            contact.ext_references.find_by(target: 'zapier')&.ext_id.to_s,
          last_updated:          contact.updated_at.in_time_zone(contact.client.time_zone).strftime('%Y/%m/%d %T'),
          last_contacted:        (contact.last_contacted ? contact.last_contacted.in_time_zone(contact.client.time_zone).strftime('%Y/%m/%d %T') : ''),
          custom_fields:,
          notes:,
          tags:,
          trusted_form_token:    contact.trusted_form&.dig(:token),
          trusted_form_cert_url: contact.trusted_form&.dig(:cert_url),
          trusted_form_ping_url: contact.trusted_form&.dig(:ping_url)
        }
      end
    end
  end
end
