# frozen_string_literal: true

# app/lib/integrations/service_titan/payments.rb
module Integrations
  module ServiceTitan
    module Payments
      # call ServiceTitan API for a payment
      # st_client.payment()
      #   (req) payment_id: (Integer)
      def payment(payment_id)
        reset_attributes
        @result = {}

        if payment_id.to_i.zero?
          @message = 'ServiceTitan Payment id is required.'
          return @result
        end

        @result = self.payments(payment_ids: [payment_id])
      end

      # call ServiceTitan API for payments
      # st_client.payments()
      #   (opt) payment_ids: (Array)
      #   (opt) customer_id: (Integer)
      def payments(args = {})
        reset_attributes
        @result   = []
        response  = @result
        page      = 0

        if !args.dig(:payment_ids).is_a?(Array) && args.dig(:customer_id).to_i.zero?
          @message = 'ServiceTitan payment ids or customer id is required.'
          return @result = []
        end

        params = { pageSize: @page_size }
        params[:ids]        = args[:payment_ids] if args.dig(:payment_ids).is_a?(Array)
        params[:customerId] = args[:customer_id] if args.dig(:customer_id).to_i.positive?

        loop do
          page += 1
          params[:page] = page

          self.servicetitan_request(
            body:                  nil,
            error_message_prepend: 'Integrations::ServiceTitan::Payments.payments',
            method:                'get',
            params:,
            default_result:        [],
            url:                   "#{base_url}/#{api_method_accounting}/#{api_version}/tenant/#{self.tenant_id}/payments"
          )

          if @result.is_a?(Hash)
            response += @result.dig(:data) || []
            break unless @result.dig(:hasMore).to_bool
          else
            response = []
            break
          end
        end

        @result = response
      end

      # call ServiceTitan API for payment types
      # st_client.payment_types
      def payment_types
        reset_attributes
        @result  = []
        response = @result
        page     = 0
        params   = { pageSize: @max_page_size }

        loop do
          page += 1
          params[:page] = page

          self.servicetitan_request(
            body:                  nil,
            error_message_prepend: 'Integrations::ServiceTitan::Payments.payment_types',
            method:                'get',
            params:,
            default_result:        [],
            url:                   "#{base_url}/#{api_method_accounting}/#{api_version}/tenant/#{self.tenant_id}/payment-types"
          )

          if @result.is_a?(Hash)
            response += @result.dig(:data) || []
            break unless @result.dig(:hasMore).to_bool
          else
            response = []
            break
          end
        end

        @result = response
      end

      # call ServiceTitan API to post a payment
      # st_client.post_payment()
      #   (req) amount_paid:        (Decimal)
      #   (req) st_invoice_id:      (Integer)
      #   (req) st_type_id:         (Integer)
      #   (opt) auth_code:          (String)
      #   (opt) check_number:       (String)
      #   (opt) comment:            (String)
      #   (opt) paid_at:            (DateTime)
      #   (opt) st_export_id:       (String)
      #   (opt) status:             (String) Pending, Posted, Exported
      #   (opt) transaction_status: (String) Success, Fail, Pending
      def post_payment(args = {})
        reset_attributes

        if args.dig(:amount_paid).to_d.zero? || args.dig(:st_invoice_id).to_i.zero? || args.dig(:st_type_id).to_i.zero?
          @message = 'Paid amount, ServiceTitan invoice id & ServiceTitan payment type id are required.'
          return @result = 0
        elsif args.dig(:status).present? && %w[pending posted exported].exclude?(args[:status].to_s.downcase)
          @message = 'Status must be either Pending, Posted or Exported.'
          return @result = 0
        elsif args.dig(:transaction_status).present? && %w[success fail pending].exclude?(args[:transaction_status].to_s.downcase)
          @message = 'Transaction status must be either Success, Fail or Pending.'
          return @result = 0
        end

        body = {
          typeId: args[:st_type_id].to_i,
          splits: [{ invoiceId: args[:st_invoice_id].to_i, amount: args[:amount_paid].to_d }]
        }

        body[:authCode]          = args[:auth_code].to_s if args.dig(:auth_code).present?
        body[:checkNumber]       = args[:check_number].to_s if args.dig(:check_number).present?
        body[:exportId]          = args[:st_export_id].to_s if args.dig(:st_export_id).present?
        body[:memo]              = args[:comment].to_s if args.dig(:comment).present?
        body[:paidOn]            = args[:paid_at].iso8601 if args.dig(:paid_at).respond_to?(:iso8601)
        body[:status]            = args[:status] if args.dig(:status).present?
        body[:transactionStatus] = args[:transaction_status] if args.dig(:transaction_status).present?

        self.servicetitan_request(
          body:,
          error_message_prepend: 'Integrations::ServiceTitan::Payments.post_payment',
          method:                'post',
          params:                nil,
          default_result:        {},
          url:                   "#{base_url}/#{api_method_accounting}/#{api_version}/tenant/#{self.tenant_id}/payments"
        )

        @result = @result.is_a?(Hash) ? @result.dig(:id).to_i : 0
      end
    end
  end
end
