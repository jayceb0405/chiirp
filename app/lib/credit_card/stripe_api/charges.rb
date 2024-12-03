# frozen_string_literal: true

# app/lib/credit_card/stripe_api/charges.rb
module CreditCard
  module StripeApi
    module Charges
      # charge a credit card using Stripe
      # result = cc_client.charge_card()
      #   (req) amount:    (Decimal)
      #   (req) client_id: (String)
      #
      #   (opt) description:  (String)
      def charge_card(**args)
        reset_attributes

        if args.dig(:client_id).to_s.empty?
          @result  = {}
          @message = 'Client token is required'
          return @result
        elsif args.dig(:amount).to_d.zero?
          @result  = {}
          @message = 'Charge amount is required'
          return @result
        end

        begin
          normalize_charge_model(Stripe::Charge.create({
                                                         amount:      (args[:amount].to_d * 100).to_i,
                                                         currency:    'usd',
                                                         customer:    args[:client_id].to_s,
                                                         description: args.dig(:description).to_s
                                                       }))
        rescue Stripe::CardError => e
          process_error(e, args)
        rescue Stripe::RateLimitError => e
          process_error(e, args)
        rescue Stripe::InvalidRequestError => e
          process_error(e, args)
        rescue Stripe::AuthenticationError => e
          process_error(e, args)
        rescue Stripe::APIConnectionError => e
          process_error(e, args)
        rescue Stripe::StripeError => e
          process_error(e, args)
        rescue StandardError => e
          process_error(e, args)
        end
      end

      private

      def normalize_charge_attributes(result)
        {
          amount:          (result.amount.to_d / 100).to_d,
          amount_captured: (result.amount_captured.to_d / 100).to_d,
          card_id:         result.payment_method.to_s,
          client_id:       result.customer.to_s,
          description:     result.description.to_s,
          message:         result.outcome.seller_message.to_s,
          status:          result.status.to_s,
          trans_id:        result.id.to_s.presence
        }
      end

      def normalize_charge_model(result)
        @faraday_result = result

        if result.is_a?(Stripe::Charge)
          @result  = normalize_charge_attributes(result)
          @success = @result[:status].casecmp?('succeeded')
        # elsif result.is_a?(Stripe::ListObject)
        #   @success = true
        #   @result  = result.data.map do |item|
        #     normalize_charge_attributes(item)
        #   end
        else
          @result = result
        end
      end
      # example Stripe::Charge
      # {
      #   id:                              'ch_3PnPl6Eo1z7FTBnw11dtwbHY',
      #   object:                          'charge',
      #   amount:                          25000,
      #   amount_captured:                 25000,
      #   amount_refunded:                 0,
      #   application:                     nil,
      #   application_fee:                 nil,
      #   application_fee_amount:          nil,
      #   balance_transaction:             'txn_3PnPl6Eo1z7FTBnw1sUhKrWx',
      #   billing_details:                 { address: { city: nil, country: nil, line1: nil, line2: nil, postal_code: nil, state: nil }, email: nil, name: nil, phone: nil },
      #   calculated_statement_descriptor: 'CHIIRP',
      #   captured:                        true,
      #   created:                         1723574872,
      #   currency:                        'usd',
      #   customer:                        'cus_EHTmI2oykEBvgw',
      #   description:                     'Test charge',
      #   destination:                     nil,
      #   dispute:                         nil,
      #   disputed:                        false,
      #   failure_balance_transaction:     nil,
      #   failure_code:                    nil,
      #   failure_message:                 nil,
      #   fraud_details:                   {},
      #   invoice:                         nil,
      #   livemode:                        false,
      #   metadata:                        {},
      #   on_behalf_of:                    nil,
      #   order:                           nil,
      #   outcome:                         { network_status: 'approved_by_network', reason: nil, risk_level: 'normal', risk_score: 25, seller_message: 'Payment complete.', type: 'authorized' },
      #   paid:                            true,
      #   payment_intent:                  nil,
      #   payment_method:                  'card_1Pn1hGEo1z7FTBnwqCI6ZVFp',
      #   payment_method_details:          { card: { amount_authorized:         25_000,
      #                                              authorization_code:        nil,
      #                                              brand:                     'visa',
      #                                              checks:                    { address_line1_check: nil, address_postal_code_check: nil, cvc_check: nil },
      #                                              country:                   'US',
      #                                              exp_month:                 8,
      #                                              exp_year:                  2030,
      #                                              extended_authorization:    { status: 'disabled' },
      #                                              fingerprint:               'B0kN2ueItnkL9wQR',
      #                                              funding:                   'credit',
      #                                              incremental_authorization: { status: 'unavailable' },
      #                                              installments:              nil,
      #                                              last4:                     '4242',
      #                                              mandate:                   nil,
      #                                              multicapture:              { status: 'unavailable' },
      #                                              network:                   'visa',
      #                                              network_token:             { used: false },
      #                                              overcapture:               { maximum_amount_capturable: 25_000, status: 'unavailable' },
      #                                              three_d_secure:            nil,
      #                                              wallet:                    nil },
      #                                      type: 'card' },
      #   receipt_email:                   'kevin@kevinneubert.com',
      #   receipt_number:                  nil,
      #   receipt_url:                     'https://pay.stripe.com/receipts/payment/CAcaFwoVYWNjdF8xRFF6ZjZFbzF6N0ZUQm53KNjU7rUGMga_XOdbUC06LBbwZlTyok1tPuAqcM-gef44ueXSLY_QT526N2s5Yp0Q9KGEAjPCCJhsPQl8',
      #   refunded:                        false,
      #   review:                          nil,
      #   shipping:                        nil,
      #   source:                          { id:                  'card_1Pn1hGEo1z7FTBnwqCI6ZVFp',
      #                                      object:              'card',
      #                                      address_city:        nil,
      #                                      address_country:     nil,
      #                                      address_line1:       nil,
      #                                      address_line1_check: nil,
      #                                      address_line2:       nil,
      #                                      address_state:       nil,
      #                                      address_zip:         nil,
      #                                      address_zip_check:   nil,
      #                                      brand:               'Visa',
      #                                      country:             'US',
      #                                      customer:            'cus_EHTmI2oykEBvgw',
      #                                      cvc_check:           nil,
      #                                      dynamic_last4:       nil,
      #                                      exp_month:           8,
      #                                      exp_year:            2030,
      #                                      fingerprint:         'B0kN2ueItnkL9wQR',
      #                                      funding:             'credit',
      #                                      last4:               '4242',
      #                                      metadata:            {},
      #                                      name:                nil,
      #                                      tokenization_method: nil,
      #                                      wallet:              nil },
      #   source_transfer:                 nil,
      #   statement_descriptor:            nil,
      #   statement_descriptor_suffix:     nil,
      #   status:                          'succeeded',
      #   transfer_data:                   nil,
      #   transfer_group:                  nil
      # }
    end
  end
end
