# frozen_string_literal: true

module Integrations
  module Sendgrid
    module Utils
      def params_email
        sanitized_params = params.permit(:'attachment-info', :attachments, :charsets, :dkim, :envelope, :from, :headers, :html, :sender_ip, :spam_report, :spam_score, :SPF, :subject, :text, :to)

        sanitized_params[:attachment_info] = (JSON.is_json?(sanitized_params[:'attachment-info']) ? JSON.parse(sanitized_params[:'attachment-info'].to_s) : sanitized_params[:'attachment-info'].to_unsafe_hash).symbolize_keys if sanitized_params.dig(:'attachment-info').present?
        sanitized_params[:attachments]     = sanitized_params.dig(:attachments).to_i
        sanitized_params[:charsets]        = (JSON.is_json?(sanitized_params[:charsets]) ? JSON.parse(sanitized_params[:charsets].to_s) : sanitized_params[:charsets].to_unsafe_hash).symbolize_keys if sanitized_params.dig(:charsets).present?
        sanitized_params[:envelope]        = (JSON.is_json?(sanitized_params[:envelope]) ? JSON.parse(sanitized_params[:envelope].to_s) : sanitized_params[:envelope].to_unsafe_hash).symbolize_keys if sanitized_params.dig(:envelope).present?
        sanitized_params[:spam_score]      = sanitized_params.dig(:spam_score).to_i
        sanitized_params.delete(:'attachment-info')

        sanitized_params
      end
    end
  end
end
