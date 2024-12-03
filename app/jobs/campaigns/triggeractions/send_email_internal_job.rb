# frozen_string_literal: true

# app/jobs/campaigns/triggeractions/send_email_internal_job.rb
module Campaigns
  module Triggeractions
    class SendEmailInternalJob < ApplicationJob
      def initialize(**args)
        super

        @process = (args.dig(:process).presence || 'send_email').to_s
      end

      # perform the ActiveJob
      #   (req) contact_id:          (Integer)
      #   (req) contact_campaign_id: (Integer)
      #   (req) triggeraction_id:    (Integer)
      def perform(**args)
        super

        # remove args[:contact] args[:contact_campaign] args[:triggeraction] after there are no more old jobs using those attributes in the db
        contact = args[:contact_id].present? ? Contact.find_by(id: args[:contact_id]) : args[:contact]
        contact_campaign = args[:contact_campaign_id].present? ? Contacts::Campaign.find_by(id: args[:contact_campaign_id]) : args[:contact_campaign]
        triggeraction = args[:triggeraction_id].present? ? Triggeraction.find_by(id: args[:triggeraction_id]) : args[:triggeraction]

        return unless contact && contact_campaign && triggeraction

        destination_target = triggeraction.send_to.present? ? triggeraction.send_to.split('_') : ['']

        to_email = case destination_target[0]
                   when 'user'
                     user = (Integer(destination_target[1], exception: false).present? && contact.client.users.find_by(id: destination_target[1])) || contact.user
                     [{ email: user&.email, name: user&.fullname }]
                   when 'orgposition'
                     position = contact.client.org_positions.find_by(id: destination_target[1])
                     position.nil? ? nil : position.org_users.map { |orguser| { email: orguser.user.email, name: orguser.user.fullname } }.compact_blank
                   when 'technician'
                     contact_job_estimate = contact.jobs.find_by(id: contact_campaign.data.dig(:contact_job_id))&.technician.presence || contact.estimates.find_by(id: contact_campaign.data.dig(:contact_job_id))&.technician.presence
                     contact_job_estimate.present? ? [{ email: contact.email, name: contact.fullname }] : nil
                   end
        return if to_email&.compact_blank&.empty?

        body    = contact.message_tag_replace(triggeraction.body)
        subject = contact.message_tag_replace(triggeraction.subject)

        if contact_campaign.data.dig(:contact_estimate_id).to_i.positive? && (contact_estimate = contact.estimates.find_by(id: contact_campaign.data[:contact_estimate_id]))
          body    = contact_estimate.message_tag_replace(body)
          subject = contact_estimate.message_tag_replace(subject)
        end

        if contact_campaign.data.dig(:contact_invoice_id).to_i.positive? && (contact_invoice = contact.invoices.find_by(id: contact_campaign.data[:contact_invoice_id]))
          body    = contact_invoice.message_tag_replace(body)
          subject = contact_invoice.message_tag_replace(subject)
        end

        if contact_campaign.data.dig(:contact_job_id).to_i.positive? && (contact_job = contact.jobs.find_by(id: contact_campaign.data[:contact_job_id]))
          body    = contact_job.message_tag_replace(body)
          subject = contact_job.message_tag_replace(subject)
        end

        if contact_campaign.data.dig(:contact_subscription_id).to_i.positive? && (contact_subscription = contact.subscriptions.find_by(id: contact_campaign.data[:contact_subscription_id]))
          body    = contact_subscription.message_tag_replace(body)
          subject = contact_subscription.message_tag_replace(subject)
        end

        if contact_campaign.data.dig(:contact_visit_id).to_i.positive? && (contact_visit = contact.visits.find_by(id: contact_campaign.data[:contact_visit_id]))
          body    = contact_visit.message_tag_replace(body)
          subject = contact_visit.message_tag_replace(subject)
        end

        app_host = I18n.with_locale(contact.client.tenant) { I18n.t("tenant.#{Rails.env}.app_host") }
        content = <<~CONTENT
          <p>Campaign: #{contact_campaign.campaign.name}</p>
          <p>
            Contact: #{contact.fullname}<br>
            #{Rails.application.routes.url_helpers.central_url(contact_id: contact.id, host: app_host)}
          </p>

          <p>#{body}</p>
        CONTENT

        e_client = Email::Base.new
        e_client.send_from_internal({
                                      to_email:,
                                      subject:,
                                      content:,
                                      client_id: contact.client_id
                                    })
        return unless e_client.success

        message = contact.messages.create({
                                            account_sid:   0,
                                            automated:     true,
                                            cost:          0,
                                            error_code:    e_client.error,
                                            error_message: e_client.message,
                                            from_phone:    'no-reply@chiirp.io',
                                            message:       subject,
                                            message_sid:   e_client.faraday_result['x-message-id'],
                                            msg_type:      'emailout',
                                            read_at:       Time.current,
                                            status:        (e_client.success? ? 'sent' : 'failed'),
                                            to_phone:      to_email.first&.dig(:email).to_s,
                                            triggeraction:
                                          })
        message.create_email(
          headers:    e_client.faraday_result.to_hash,
          html_body:  content,
          bcc_emails: [],
          cc_emails:  [],
          to_emails:  [to_email]
        )
      end
    end
  end
end
