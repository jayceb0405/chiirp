# frozen_string_literal: true

# app/lib/credit_card/stripe_api/subscription_schedules.rb
module CreditCard
  module StripeApi
    module SubscriptionSchedules
      # retrieve a Stripe::SubscriptionSchedule
      # result = CreditCard::StripeApi::Base.new.subscription_schedule()
      #   (req) subscription_schedule_id: (String)
      def subscription_schedule(**args)
        return nil if args.dig(:subscription_schedule_id).to_s.empty?

        begin
          normalize_subscription_schedule_model(Stripe::SubscriptionSchedule.retrieve(args[:subscription_schedule_id].to_s))
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

      # create a new Subscription Schedule for a customer
      # result = CreditCard::StripeApi::SubscriptionSchedules.subscription_schedule_create()
      #   (req) client_id:    (String)
      #   (req) phases:       (Array of Hashes)
      #     (req) description:  (String)
      #     (opt) end_at:       (DateTime)
      #     (req) items:        (Array of Hashes)
      #       (req) price:    (String)
      #       (opt) quantity: (Integer / default: 1)
      #     (opt) trial_end_at: (DateTime)
      #   (req) start_at:     (DateTime)
      def subscription_schedule_create(**args)
        return nil if args.dig(:client_id).to_s.empty? || !args.dig(:start_at).respond_to?(:to_time) ||
                      !args.dig(:phases).is_a?(Array) || args[:phases].empty?

        begin
          params = {
            customer:     args[:client_id].to_s,
            end_behavior: 'release',
            phases:       [],
            start_date:   args[:start_at].to_i # UNIX timestamp
          }

          args.dig(:phases).each do |phase|
            new_phase = {
              billing_cycle_anchor: 'automatic',
              collection_method:    'charge_automatically',
              description:          phase[:description].to_s,
              items:                [],
              proration_behavior:   'none'
            }
            new_phase[:end_date]  = phase[:start_at].to_i if phase[:end_at].present? # UNIX timestamp
            new_phase[:trial_end] = phase[:trial_end_at].to_i if phase[:trial_end_at].present? # UNIX timestamp

            phase.dig(:items).each do |item|
              new_phase[:items] << {
                price:    item.dig(:price).to_s,
                quantity: (item.dig(:quantity).presence || 1).to_i
              }
            end

            params[:phases] << new_phase
          end

          normalize_subscription_schedule_model(Stripe::SubscriptionSchedule.create(**params))
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

      # list Subscription Schedules for a customer
      # result = CreditCard::StripeApi::Base.new.subscription_schedules()
      #   (req) client_id: (String)
      def subscription_schedules(**args)
        return nil if args.dig(:client_id).to_s.empty?

        begin
          data = []
          result = {}
          starting_after = nil

          loop do
            params = {
              customer: args[:client_id].to_s,
              limit:    100
            }
            params[:starting_after] = starting_after if starting_after.present?

            result = Stripe::SubscriptionSchedule.list(**params)

            data += result.data

            break unless result.has_more

            starting_after = result.starting_after
          end

          result.data = data

          normalize_subscription_schedule_model(result)
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

      def normalize_subscription_schedule_attributes(result)
        response = {
          active:                   result.status.to_s.case_cmp?('active'),
          canceled_at:              result.canceled_at,
          client_id:                result.customer.to_s,
          completed_at:             result.completed_at,
          current_phase:            result.current_phase,
          customer_id:              result.customer.to_s,
          end_behavior:             result.end_behavior,
          metadata:                 result.metadata,
          phases:                   [],
          status:                   result.status.to_s,
          subscription_id:          result.subscription.to_s,
          subscription_schedule_id: result.id.to_s
        }
        result.phases.each do |phase|
          new_phase = {
            description: phase.description.to_s,
            items:       [],
            metadata:    phase.metadata,
            start_date:  phase.start_date,
            trial_end:   phase.trial_end
          }

          phase.items.each do |item|
            new_phase[:items] << {
              metadata: item.metadata,
              price_id: item.price.to_s,
              quantity: item.quantity
            }
          end

          response[:phases] << new_phase
        end

        response
      end

      def normalize_subscription_schedule_model(result)
        @faraday_result = result

        if result.is_a?(Stripe::SubscriptionSchedule)
          normalize_subscription_schedule_attributes(result)
        elsif result.is_a?(Stripe::ListObject)
          result.data.map do |item|
            normalize_subscription_schedule_attributes(item)
          end
        end
      end
      # example Stripe::SubscriptionSchedule
      # {
      #   id:                    'sub_sched_1PnoHhEo1z7FTBnwSVJJhFeX',
      #   object:                'subscription_schedule',
      #   application:           null,
      #   canceled_at:           null,
      #   completed_at:          null,
      #   created:               1723669149,
      #   current_phase:         { end_date: 1726347549, start_date: 1723669149 },
      #   customer:              'cus_EHTmI2oykEBvgw',
      #   default_settings:      {
      #     application_fee_percent: null,
      #     automatic_tax:           { enabled: false, liability: null },
      #     billing_cycle_anchor:    'automatic',
      #     billing_thresholds:      null,
      #     collection_method:       'charge_automatically',
      #     default_payment_method:  null,
      #     default_source:          null,
      #     description:             null,
      #     invoice_settings:        { account_tax_ids: null, days_until_due: null, issuer: { type: 'self' } },
      #     on_behalf_of:            null,
      #     transfer_data:           null
      #   },
      #   end_behavior:          'release',
      #   livemode:              false,
      #   metadata:              {},
      #   phases:                [
      #     {
      #       add_invoice_items:       [],
      #       application_fee_percent: null,
      #       billing_cycle_anchor:    'automatic',
      #       billing_thresholds:      null,
      #       collection_method:       'charge_automatically',
      #       coupon:                  null,
      #       currency:                'usd',
      #       default_payment_method:  null,
      #       default_tax_rates:       [],
      #       description:             'Test period',
      #       discounts:               [],
      #       end_date:                1726347549,
      #       invoice_settings:        null,
      #       items:                   [
      #         {
      #           billing_thresholds: null,
      #           discounts:          [],
      #           metadata:           {},
      #           plan:               'plan_DslkSy2jmvpDtu',
      #           price:              'plan_DslkSy2jmvpDtu',
      #           quantity:           1,
      #           tax_rates:          []
      #         }
      #       ],
      #       metadata:                {},
      #       on_behalf_of:            null,
      #       proration_behavior:      'none',
      #       start_date:              1723669149,
      #       transfer_data:           null,
      #       trial_end:               null
      #     }
      #   ],
      #   released_at:           null,
      #   released_subscription: null,
      #   renewal_interval:      null,
      #   status:                'active',
      #   subscription:          'sub_1PnoHhEo1z7FTBnwMEQu0JST',
      #   test_clock:            null
      # }
      # example Stripe::ListObject response when no data exists
      # {
      #   object:   'list',
      #   data:     [],
      #   has_more: false,
      #   url:      '/v1/subscription_schedules'
      # }
      # example Stripe::ListObject response when data exists
      # {
      #   object:   'list',
      #   data:     [
      #     {
      #       id:                    'sub_sched_1PnoHhEo1z7FTBnwSVJJhFeX',
      #       object:                'subscription_schedule',
      #       application:           null,
      #       canceled_at:           null,
      #       completed_at:          null,
      #       created:               1723669149,
      #       current_phase:         { end_date: 1726347549, start_date: 1723669149 },
      #       customer:              'cus_EHTmI2oykEBvgw',
      #       default_settings:      {
      #         application_fee_percent: null,
      #         automatic_tax:           { enabled: false, liability: null },
      #         billing_cycle_anchor:    'automatic',
      #         billing_thresholds:      null,
      #         collection_method:       'charge_automatically',
      #         default_payment_method:  null,
      #         default_source:          null,
      #         description:             null,
      #         invoice_settings:        { account_tax_ids: null, days_until_due: null, issuer: { type: 'self' } },
      #         on_behalf_of:            null,
      #         transfer_data:           null
      #       },
      #       end_behavior:          'release',
      #       livemode:              false,
      #       metadata:              {},
      #       phases:                [
      #         {
      #           add_invoice_items:       [],
      #           application_fee_percent: null,
      #           billing_cycle_anchor:    'automatic',
      #           billing_thresholds:      null,
      #           collection_method:       'charge_automatically',
      #           coupon:                  null,
      #           currency:                'usd',
      #           default_payment_method:  null,
      #           default_tax_rates:       [],
      #           description:             'Test period',
      #           discounts:               [],
      #           end_date:                1726347549,
      #           invoice_settings:        null,
      #           items:                   [
      #             {
      #               billing_thresholds: null,
      #               discounts:          [],
      #               metadata:           {},
      #               plan:               'plan_DslkSy2jmvpDtu',
      #               price:              'plan_DslkSy2jmvpDtu',
      #               quantity:           1,
      #               tax_rates:          []
      #             }
      #           ],
      #           metadata:                {},
      #           on_behalf_of:            null,
      #           proration_behavior:      'none',
      #           start_date:              1723669149,
      #           transfer_data:           null,
      #           trial_end:               null
      #         }
      #       ],
      #       released_at:           null,
      #       released_subscription: null,
      #       renewal_interval:      null,
      #       status:                'active',
      #       subscription:          'sub_1PnoHhEo1z7FTBnwMEQu0JST',
      #       test_clock:            null
      #     }
      #   ],
      #   has_more: false,
      #   url:      '/v1/subscription_schedules'
      # }
    end
  end
end
