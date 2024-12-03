# frozen_string_literal: true

# app/models/integration/fieldroutes/v1/employees.rb
module Integration
  module Fieldroutes
    module V1
      module Subscriptions
        # find or create a Contacts::Subscription based on incoming webhook data
        def subscription(contact, **args)
          return false unless contact.is_a?(Contact) && args.dig(:subscriptionID).present? && args.dig(:customerID).present? &&
                              (contact_subscription = contact.subscriptions.find_or_initialize_by(ext_source: 'fieldroutes', ext_id: args[:subscriptionID])).present?

          contact_subscription.update(
            customer_id:     (args.dig(:customerID).presence || contact_subscription.customer_id).to_s,
            customer_number: (args.dig(:customerNumber).presence || contact_subscription.customer_number).to_s,
            firstname:       (args.dig(:fname).presence || contact_subscription.firstname).to_s,
            lastname:        (args.dig(:lname).presence || contact_subscription.lastname).to_s,
            companyname:     (args.dig(:companyName).presence || contact_subscription.companyname).to_s,
            address_01:      (args.dig(:address).presence || contact_subscription.address_01).to_s,
            city:            (args.dig(:city).presence || contact_subscription.city).to_s,
            state:           (args.dig(:state).presence || contact_subscription.state).to_s,
            postal_code:     (args.dig(:zip).presence || contact_subscription.postal_code).to_s,
            total:           (args.dig(:total).presence || contact_subscription.total).to_d,
            total_due:       (args.dig(:totalDue).presence || contact_subscription.total_due).to_d,
            description:     (args.dig(:description).presence || contact_subscription.description).to_s,
            added_at:        added_at_from_webhook(contact, **args) || contact_subscription.added_at,
            cancelled_at:    cancelled_at_from_webhook(contact, **args) || contact_subscription.cancelled_at
          )

          contact_subscription
        end

        def added_at_from_webhook(contact, **args)
          Chronic.parse(args.dig(:dateAdded).to_s)&.utc&.beginning_of_day
        end

        def cancelled_at_from_webhook(contact, **args)
          Chronic.parse(args.dig(:dateCancelled).to_s)&.utc&.beginning_of_day
        end
      end
    end
  end
end
