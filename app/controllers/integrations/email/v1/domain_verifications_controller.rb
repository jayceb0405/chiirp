# frozen_string_literal: true

# Integrations::Email::V1::DomainVerificationsController
module Integrations
  module Email
    module V1
      class DomainVerificationsController < Integrations::Email::V1::IntegrationsController
        # (GET) Email Verifications controller
        # /integrations/email/v1/domain_verifications
        # integrations_email_v1_domain_verifications_path
        # integrations_email_v1_domain_verifications_url
        def show
          render partial: 'integrations/email/v1/js/show', locals: { cards: %w[menu domain_verifications] }
        end

        # (POST) Email Verifications controller verify
        # /integrations/email/v1/domain_verifications
        # integrations_email_v1_domain_verifications_path
        # integrations_email_v1_domain_verifications_url
        def create
          Integrations::Email::V1::VerifyDomainsJob.perform_later(client_api_integration: @client_api_integration)

          render partial: 'integrations/email/v1/js/show', locals: { cards: %w[] }
        end
      end
    end
  end
end
