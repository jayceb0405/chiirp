# frozen_string_literal: true

# app/presenters/integrations/jotform/v1/presenter.rb
module Integrations
  module Jotform
    module V1
      class Presenter < BasePresenter
        # Integrations::Jotform::V1::Presenter.new(user_api_integration: @user_api_integration)
        #   (req) user_api_integration: (UserApiIntegration) or (Integer)

        def initialize(args = {})
          super

          @jf_client                 = Integrations::JotForm::V1::Base.new(@user_api_integration.api_key, @user_api_integration.jotform_forms)
          @jotform_forms             = nil
          @options_for_campaign_hash = nil
          @options_for_key_hash      = nil
        end

        def webhook(form_id)
          @jf_client.form_webhooks(form_id)&.find { |_key, value| value.include?('/integrations/jotform/integration/endpoint') }
        end

        def jotform_forms
          @jotform_forms ||= @jf_client.forms
        end

        def options_for_campaign_hash
          @options_for_campaign_hash ||= Campaign.for_select(@client.id).pluck(:name, :id)
        end

        def options_for_key_hash
          @options_for_key_hash ||= ::Webhook.internal_key_hash(@client, 'contact', %w[personal ext_references]).invert.to_a + [['OK to Text', 'ok2text'], ['OK to Email', 'ok2email']] + ::Webhook.internal_key_hash(@client, 'contact', %w[phones]).merge(@client.client_custom_fields.pluck(:id, :var_name).to_h).invert.to_a
        end
      end
    end
  end
end
