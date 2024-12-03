# frozen_string_literal: true

module Integrations
  module Cardx
    class ServiceTitansController < Integrations::Cardx::IntegrationsController
      # (GET) CardX ServiceTitan index
      # /integrations/cardx/service_titan
      # integrations_cardx_v3_service_titans_path
      # integrations_cardx_v3_service_titans_url
      def edit
        @client_api_integration.update(service_titan: {}) unless @client_api_integration.service_titan

        render partial: 'integrations/cardx/js/show', locals: { cards: %w[service_titan_edit] }
      end

      # (PUT/PATCH) CardX ServiceTitan screen
      # /integrations/cardx/service_titan/:id
      # integrations_cardx_v3_service_titan_path
      # integrations_cardx_v3_service_titan_url
      def update
        @client_api_integration.update(service_titan: service_titan_params)

        render partial: 'integrations/cardx/js/show', locals: { cards: %w[service_titan_edit] }
      end

      private

      # def defaults
      #   {
      #     post_payments: false,
      #     payment_type:  nil,
      #     comment:       nil
      #   }
      # end

      def service_titan_params
        sanitized_params = params.require(:service_titan).permit(:post_payments, :payment_type, :comment)

        sanitized_params[:post_payments] = sanitized_params.dig(:post_payments)&.strip
        sanitized_params[:payment_type] = sanitized_params.dig(:payment_type)&.strip
        sanitized_params[:comment] = sanitized_params.dig(:comment)&.strip

        sanitized_params
      end
    end
  end
end
