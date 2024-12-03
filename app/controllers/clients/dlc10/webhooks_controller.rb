# frozen_string_literal: true

# app/controllers/clients/dlc10/webhooks_controller.rb
module Clients
  module Dlc10
    class WebhooksController < Clients::Dlc10::BaseController
      class ClientsDlc10WebhooksMissingEventType < StandardError; end

      skip_before_action :verify_authenticity_token
      skip_before_action :authenticate_user!
      skip_before_action :client
      skip_before_action :authorize_user!

      # (POST) receive CampaignRegistry webhook
      # /clients/dlc10/webhooks/endpoint
      # clients_dlc10_webhook_endpoint_path
      # clients_dlc10_webhook_endpoint_url
      def endpoint
        event_type = params.permit(:eventType).dig(:eventType).to_s

        case event_type
        when 'BRAND_ADD', 'BRAND_IDENTITY_STATUS_UPDATE'
          sanitized_params = params_brand

          # verify that verified_at is blank to be sure this webhook is not a duplicate
          if sanitized_params.dig(:brandId).present? && (dlc10_brand = Clients::Dlc10::Brand.find_by(id: sanitized_params[:brandReferenceId])) && dlc10_brand.verified_at.nil?

            if event_type.casecmp?('BRAND_ADD')
              dlc10_brand.update(tcr_brand_id: sanitized_params[:brandId].to_s, verified_at: Time.current)
            elsif event_type.casecmp?('BRAND_IDENTITY_STATUS_UPDATE')
              dlc10_brand.update(tcr_brand_id: sanitized_params[:brandId].to_s, verified_at: sanitized_params.dig(:brandIdentityStatus).casecmp?('verified') ? Time.current : nil)
            end

            # submit the campaign if there is only a single campaign, that hasn't been accepted yet
            # trying a 1 hour delay to to give TCR time to update the status of the Brand
            Clients::Dlc10::SubmitCampaignJob.set(wait_until: Random.rand(60).minutes.from_now).perform_later(dlc10_campaign_id: dlc10_brand.campaigns.first.id) if dlc10_brand.campaigns.one? && dlc10_brand.campaigns.first.accepted_at.nil?

            broadcast_verified_to_users(dlc10_brand)
          end
        when 'BRAND_DELETE'
          sanitized_params = params_brand

          if sanitized_params.dig(:brandId).present? && (dlc10_brand = Clients::Dlc10::Brand.find_by(id: sanitized_params[:brandReferenceId])) && dlc10_brand.tcr_brand_id.casecmp?(sanitized_params[:brandId].to_s)
            dlc10_brand.update(tcr_brand_id: '', submitted_at: nil, resubmitted_at: nil, verified_at: nil)
          end
        when 'BRAND_APPEAL_COMPLETE', 'BRAND_IDENTITY_VET_UPDATE', 'BRAND_REVET', 'BRAND_UPDATE'
          # ignore this webhook
        when 'CAMPAIGN_ADD'
          sanitized_params = params_campaign

          if sanitized_params.dig(:campaignId).present? && sanitized_params.dig(:campaignReferenceId).present? &&
             (dlc10_campaign = Clients::Dlc10::Campaign.find_by(id: sanitized_params[:campaignReferenceId].split('_').first.to_i)) && dlc10_campaign.next_mo_date.blank?
            dlc10_campaign.update(
              next_mo_date:    Date.current.end_of_month,
              tcr_campaign_id: sanitized_params[:campaignId],
              accepted_at:     Time.current
            )
          end
        when 'CAMPAIGN_BILLED', 'CAMPAIGN_UPDATE'
          # ignore this webhook
        when 'CAMPAIGN_DCA_COMPLETE'
          sanitized_params = params_campaign

          if sanitized_params.dig(:campaignId).present? && (dlc10_campaign = Clients::Dlc10::Campaign.find_by(tcr_campaign_id: sanitized_params[:campaignId]))
            dlc10_campaign.update(dca_completed_at: Time.current)

            dlc10_campaign.brand.client.twnumbers.where(dlc10_campaign_id: nil).find_each do |twnumber|
              dlc10_campaign.share_phone_number(twnumber)
            end

            if (contact = dlc10_campaign.brand.client.corp_contact)
              content = "10dlc Campaign: #{dlc10_campaign.name} was accepted."
              contact.delay(
                run_at:     send_at(dlc10_campaign.brand.client),
                priority:   DelayedJob.job_priority('send_text'),
                queue:      DelayedJob.job_queue('send_text'),
                contact_id: contact.id,
                user_id:    contact.user_id,
                data:       { content:, msg_type: 'textout' },
                process:    'send_text'
              ).send_text(content:, msg_type: 'textout')
            end
          end
          # example webhook for CAMPAIGN_DCA_COMPLETE
          # {
          #   action:              'endpoint',
          #   brandId:             'BUTNE6G',
          #   brandName:           'On Duty Chimney',
          #   brandReferenceId:    '1116',
          #   campaignId:          'CT8MUVN',
          #   campaignReferenceId: '797_BANDW_a',
          #   controller:          'clients/dlc10/webhooks',
          #   cspId:               'SBJAF5P',
          #   cspName:             'Chiirp',
          #   description:         'Campaign DCAs have been fully elected for campaign CT8MUVN',
          #   eventType:           'CAMPAIGN_DCA_COMPLETE',
          #   mock:                false
          # }
        when 'CAMPAIGN_EXPIRED'
          sanitized_params = params_campaign

          if sanitized_params.dig(:campaignReferenceId).present? && (dlc10_campaign = Clients::Dlc10::Campaign.find_by(id: sanitized_params[:campaignReferenceId].split('_').first.to_i))
            dlc10_campaign.update(tcr_campaign_id: '', accepted_at: nil)
          end
        when 'CAMPAIGN_SHARE_ACCEPT'
          sanitized_params = params_campaign_share

          if sanitized_params.dig(:campaignId).present? && (dlc10_campaign = Clients::Dlc10::Campaign.find_by(tcr_campaign_id: sanitized_params[:campaignId]))
            dlc10_campaign.update(accepted_at: Time.current)
          end
        when 'CAMPAIGN_SHARE_ADD'
          sanitized_params = params_campaign_share

          if sanitized_params.dig(:campaignId).present? && (dlc10_campaign = Clients::Dlc10::Campaign.find_by(tcr_campaign_id: sanitized_params[:campaignId]))
            dlc10_campaign.update(shared_at: Time.current)
          end
        when 'CAMPAIGN_SHARE_DELETE'
          sanitized_params = params_campaign_share

          if sanitized_params.dig(:campaignId).present? && (dlc10_campaign = Clients::Dlc10::Campaign.find_by(tcr_campaign_id: sanitized_params[:campaignId]))
            dlc10_campaign.update(
              shared_at:   nil,
              accepted_at: nil
            )

            if (contact = dlc10_campaign.brand.client.corp_contact)
              content = "10dlc Campaign: #{dlc10_campaign.name} was NOT accepted. Comments: #{sanitized_params.dig(:description).presence || 'None'}"
              contact.delay(
                run_at:     send_at(dlc10_campaign.brand.client),
                priority:   DelayedJob.job_priority('send_text'),
                queue:      DelayedJob.job_queue('send_text'),
                contact_id: contact.id,
                user_id:    contact.user_id,
                data:       { content:, msg_type: 'textout' },
                process:    'send_text'
              ).send_text(content:, msg_type: 'textout')
            end
          end
        when 'BRAND_MOCK_OTP', 'BRAND_OTP_VERIFIED', 'BRAND_SCORE_UPDATE', 'CAMPAIGN_NUDGE', 'CAMPAIGN_RESUBMISSION'
          # ignore these webhooks
        else
          error = ClientsDlc10WebhooksMissingEventType.new("Unknown event type: #{event_type}")
          error.set_backtrace(BC.new.clean(caller))

          Appsignal.report_error(error) do |transaction|
            # Only needed if it needs to be different or there's no active transaction from which to inherit it
            Appsignal.set_action('Clients::Dlc10::WebhooksController#endpoint')

            # Only needed if you want to set different arguments or there's no active transaction from which to inherit it
            Appsignal.add_params(params)

            Appsignal.set_tags(
              error_level: 'info',
              error_code:  0
            )
            Appsignal.add_custom_data(
              event_type:,
              file:       __FILE__,
              line:       __LINE__
            )
          end
        end

        render plain: 'Success', content_type: 'text/plain', status: :ok, layout: false
      end

      private

      def broadcast_verified_to_users(dlc10_brand)
        presenter = Clients::Dlc10::V2::Presenter.new(client: dlc10_brand.client)

        dlc10_brand.client.users.find_each do |user|
          presenter.user = user
          html = ApplicationController.render partial: 'clients/dlc10/v2/edit', locals: { presenter: }
          UserCable.new.broadcast(dlc10_brand.client, user, { append: 'false', id: 'client_page_section', html: })
        end
      end

      def params_brand
        sanitized_params = params.permit(:brandName, :brandId, :brandIdentityStatus, :brandReferenceId, :cspId, :cspName, :description, :eventType, :mock)

        sanitized_params[:brandReferenceId] = sanitized_params.dig(:brandReferenceId).to_i
        sanitized_params[:mock]             = sanitized_params.dig(:mock).to_bool

        sanitized_params
      end

      def params_campaign
        sanitized_params = params.permit(:brandName, :brandId, :brandReferenceId, :campaignId, :campaignReferenceId, :cspId, :cspName, :description, :eventType, :mock)

        sanitized_params[:brandReferenceId]    = sanitized_params.dig(:brandReferenceId).to_s
        sanitized_params[:campaignReferenceId] = sanitized_params.dig(:campaignReferenceId).to_s
        sanitized_params[:mock]                = sanitized_params.dig(:mock).to_bool

        sanitized_params
      end

      def params_campaign_share
        params.permit(:brandId, :brandName, :brandReferenceId, :campaignId, :campaignReferenceId, :cspId, :cspName, :description, :eventType, :mock)
      end

      def send_at(client)
        AcceptableTime.new(
          time_zone:  client.time_zone,
          safe_start: 480,
          safe_end:   1200,
          safe_sun:   false,
          safe_mon:   true,
          safe_tue:   true,
          safe_wed:   true,
          safe_thu:   true,
          safe_fri:   true,
          safe_sat:   true,
          holidays:   {}
        ).new_time(Time.current)
      end
    end
  end
end

# Acceptable eventTypes:
#   [
#     {:eventType=>"BRAND_ADD", :description=>"Brand Added", :eventCategory=>"BRAND"},
#     {:eventType=>"BRAND_DELETE", :description=>"Brand deleted", :eventCategory=>"BRAND"},
#     {:eventType=>"BRAND_IDENTITY_STATUS_UPDATE", :description=>"Brand identity status changed", :eventCategory=>"BRAND"},
#     {:eventType=>"BRAND_MOCK_OTP", :description=>"Mock Brand OTP sent", :eventCategory=>"BRAND"},
#     {:eventType=>"BRAND_OTP_VERIFIED", :description=>"Brand OTP verification completed", :eventCategory=>"BRAND"},
#     {:eventType=>"BRAND_SCORE_UPDATE", :description=>"Brand Entity Score Updated", :eventCategory=>"BRAND"},
#     {:eventType=>"CAMPAIGN_ADD", :description=>"Campaign Added", :eventCategory=>"CAMPAIGN"},
#     {:eventType=>"CAMPAIGN_BILLED", :description=>"Campaign is billed", :eventCategory=>"CAMPAIGN"},
#     {:eventType=>"CAMPAIGN_DCA_COMPLETE", :description=>"Campaign DCA elections completed", :eventCategory=>"CAMPAIGN"},
#     {:eventType=>"CAMPAIGN_EXPIRED", :description=>"Campaign Deactivated", :eventCategory=>"CAMPAIGN"},
#     {:eventType=>"CAMPAIGN_NUDGE", :description=>"Nudge a party in connectivity partner chain", :eventCategory=>"CAMPAIGN"},
#     {:eventType=>"CAMPAIGN_RESUBMISSION", :description=>"Campaign Re-submitted", :eventCategory=>"CAMPAIGN"},
#     {:eventType=>"CAMPAIGN_SHARE_ACCEPT", :description=>"Campaign CNP accepted nomination", :eventCategory=>"CAMPAIGN"},
#     {:eventType=>"CAMPAIGN_SHARE_ADD", :description=>"Campaign CNP nominated", :eventCategory=>"CAMPAIGN"},
#     {:eventType=>"CAMPAIGN_SHARE_DELETE", :description=>"Campaign CNP declined", :eventCategory=>"CAMPAIGN"},
#     {:eventType=>"CSP_ACTIVE", :description=>"CSP Activated", :eventCategory=>"CSP"},
#     {:eventType=>"CSP_APPROVE", :description=>"CSP application approved", :eventCategory=>"CSP"},
#     {:eventType=>"CSP_SUSPEND", :description=>"CSP Suspended", :eventCategory=>"CSP"},
#     {:eventType=>"EVP_REPORT_EXPIRE", :description=>"Vetting Report Expired", :eventCategory=>"VETTING"},
#     {:eventType=>"EVP_REPORT_EXPRESS_MAIL", :description=>"Pass-through express delivery service", :eventCategory=>"VETTING"},
#     {:eventType=>"EVP_REPORT_FAIL", :description=>"Vetting provider reported Vetting Failure", :eventCategory=>"VETTING"},
#     {:eventType=>"EVP_REPORT_IMPORT", :description=>"Vetting Report Imported", :eventCategory=>"VETTING"},
#     {:eventType=>"EVP_REPORT_SCORE", :description=>"Vetting Provider reported Score", :eventCategory=>"VETTING"},
#     {:eventType=>"EVP_REPORT_UNSCORE", :description=>"Vetting Provider reported UnScore", :eventCategory=>"VETTING"},
#     {:eventType=>"EVP_REPORT_UPDATE", :description=>"Vetting Report Updated", :eventCategory=>"VETTING"},
#     {:eventType=>"MNO_CAMPAIGN_OPERATION_APPROVED", :description=>"Campaign Approved", :eventCategory=>"CAMPAIGN"},
#     {:eventType=>"MNO_CAMPAIGN_OPERATION_REJECTED", :description=>"MNO Campaign Rejected", :eventCategory=>"CAMPAIGN"},
#     {:eventType=>"MNO_CAMPAIGN_OPERATION_REVIEW", :description=>"Campaign submitted for MNO review", :eventCategory=>"CAMPAIGN"},
#     {:eventType=>"MNO_CAMPAIGN_OPERATION_SUSPENDED", :description=>"MNO Campaign Suspended", :eventCategory=>"CAMPAIGN"},
#     {:eventType=>"MNO_CAMPAIGN_OPERATION_UNSUSPENDED", :description=>"MNO Lifted Campaign Suspension", :eventCategory=>"CAMPAIGN"},
#     {:eventType=>"MNO_COMPLAINT", :description=>"Complaint Reported by MNO", :eventCategory=>"INCIDENCE"}
#   ]

# Examples
# BRAND_ADD
#   {
#     "cspId"=>"SBJAF5P",
#     "brandName"=>"hookingTest",
#     "brandReferenceId"=>nil,
#     "brandId"=>"B6GZY9I",
#     "description"=>"Brand B6GZY9I (hookingTest) is added",
#     "mock"=>false,
#     "eventType"=>"BRAND_ADD",
#     "cspName"=>"Chiirp"
#   }
# BRAND_DELETE
#   {
#     "cspId"=>"SBJAF5P",
#     "brandName"=>"hookingTest",
#     "brandReferenceId"=>nil,
#     "brandId"=>"B6GZY9I",
#     "description"=>"Brand B6GZY9I (hookingTest) is deleted",
#     "mock"=>false,
#     "eventType"=>"BRAND_DELETE",
#     "cspName"=>"Chiirp"
#   }
# CAMPAIGN_ADD
#   {
#     "cspId"=>"SBJAF5P",
#     "brandName"=>"zz",
#     "campaignId"=>"C8PWPWB",
#     "brandReferenceId"=>"adfert111",
#     "brandId"=>"B5HDZSA",
#     "description"=>"Campaign C8PWPWB for brand B5HDZSA (zz) is provisioned in the registry",
#     "mock"=>false,
#     "eventType"=>"CAMPAIGN_ADD",
#     "cspName"=>"Chiirp",
#     "campaignReferenceId"=>nil
#   }
# CAMPAIGN_DCA_COMPLETE
#   {
#     "action"=>"endpoint",
#     "brandId"=>"BSAZ4N7",
#     "brandName"=>"Larson's Chem-Dry",
#     "brandReferenceId"=>"836",
#     "campaignId"=>"CC3QRHL",
#     "campaignReferenceId"=>"575_BANDW_a",
#     "controller"=>"clients/dlc10/webhooks",
#     "cspId"=>"SBJAF5P",
#     "cspName"=>"Chiirp"
#     "description"=>"Campaign DCAs have been fully elected for campaign CC3QRHL",
#     "eventType"=>"CAMPAIGN_DCA_COMPLETE",
#     "mock"=>false
#   }
# CAMPAIGN_EXPIRED
#   {
#     "cspId"=>"SBJAF5P",
#     "brandName"=>"zz",
#     "campaignId"=>"C8PWPWB",
#     "brandReferenceId"=>"adfert111",
#     "brandId"=>"B5HDZSA",
#     "description"=>"Campaign C8PWPWB for brand B5HDZSA (zz) is deactivated",
#     "mock"=>false,
#     "eventType"=>"CAMPAIGN_EXPIRED",
#     "cspName"=>"Chiirp",
#     "campaignReferenceId"=>nil
#   }
# CAMPAIGN_SHARE_ACCEPT
#   {
#     "campaignId"=>"CLW28YB",
#     "eventType"=>"CAMPAIGN_SHARE_ACCEPT"
#   }
# CAMPAIGN_SHARE_ADD
#   {
#     "campaignId"=>"CLW28YB",
#     "eventType"=>"CAMPAIGN_SHARE_ADD"
#   }
# CAMPAIGN_SHARE_DELETE
#   {
#     "campaignId"=>"CLW28YB",
#     "eventType"=>"CAMPAIGN_SHARE_DELETE"
#   }
