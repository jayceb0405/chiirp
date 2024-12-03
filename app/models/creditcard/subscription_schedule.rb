# frozen_string_literal: true

# app/models/creditcard/subscription_schedule.rb
module Creditcard
  class SubscriptionSchedule < Creditcard::Base
    attribute :active, :boolean, default: true
    attribute :canceled_at, :datetime
    attribute :client_id, :string
    attribute :completed_at, :datetime
    attribute :current_phase, :string
    attribute :customer_id, :string
    attribute :end_behavior, :string
    attribute :metadata, :string, default: -> { {}.to_json }
    attribute :phases, :string, default: -> { {}.to_json }
    attribute :status, :string
    attribute :subscription_id, :string
    attribute :subscription_schedule_id, :string

    validates :active, :client_id, :current_phase, :customer_id, :status, :subscription_id, :subscription_schedule_id, presence: true

    # create a new Subscription Schedule for a customer
    # subscription_schedule = CreditCard::SubscriptionSchedule.create()
    #   (req) client_id:    (String)
    #   (req) phases:       (Array of Hashes)
    #     (req) description:  (String)
    #     (opt) end_at:       (DateTime)
    #     (req) items:        (Array of Hashes)
    #       (req) price_id: (String)
    #       (opt) quantity: (Integer / default: 1)
    #     (opt) trial_end_at: (DateTime)
    #   (req) start_at:     (DateTime)
    def self.create(**args)
      cc_client.subscription_schedule_create(**args)

      if cc_client.success?
        new_attributes_from_result(cc_client.result)
      else
        new_subscription_schedule = new_attributes_from_result(**args)
        new_subscription_schedule.errors.add(:subscription_schedule, cc_client.message)

        new_subscription_schedule
      end
    end

    # retrieve a subscription schedule
    # subscription_schedule = Creditcard::SubscriptionSchedule.find_by()
    #   (req) subscription_schedule_id: (String)
    def self.find_by(**args)
      cc_client.subscription_schedule(**args)

      if cc_client.success?
        new_attributes_from_result(cc_client.result)
      else
        nil
      end
    end

    def metadata
      JSON.parse(self.attributes.dig('metadata')).symbolize_keys
    end

    def metadata=(value)
      _write_attribute('metadata', value.to_json)
    end

    def phases
      JSON.parse(self.attributes.dig('phases')).symbolize_keys
    end

    def phases=(value)
      _write_attribute('phases', value.to_json)
    end

    # list all subscriptions for a customer
    # subscription_schedules = Creditcard::SubscriptionSchedule.where()
    #   (req) client_id: (String)
    def self.where(**args)
      cc_client.subscription_schedules(**args)

      if cc_client.success?
        response = []

        cc_client.result.each do |subscription_schedule|
          response << new_attributes_from_result(subscription_schedule)
        end

        response
      else
        []
      end
    end

    private

    def self.new_attributes_from_result(result)
      response = self.new
      response.active                   = result.dig(:active).to_bool
      response.canceled_at              = result.dig(:canceled_at)
      response.client_id                = result.dig(:client_id)
      response.completed_at             = result.dig(:completed_at)
      response.current_phase            = result.dig(:current_phase)
      response.customer_id              = result.dig(:customer_id)
      response.end_behavior             = result.dig(:end_behavior)
      response.metadata                 = result.dig(:metadata).presence || {}
      response.phases                   = result.dig(:phases).presence || {}
      response.status                   = result.dig(:status)
      response.subscription_id          = result.dig(:subscription_id)
      response.subscription_schedule_id = result.dig(:subscription_schedule_id)

      # result.dig(:phases)&.each do |phase|
      #   new_phase = {
      #     description: phase.dig(:description).to_s,
      #     items:       [],
      #     metadata:    phase.dig(:metadata),
      #     start_date:  phase.dig(:start_date),
      #     trial_end:   phase.dig(:trial_end)
      #   }

      #   phase.items&.each do |item|
      #     new_phase[:items] << {
      #       metadata: item.dig(:metadata),
      #       price_id: item.dig(:price).to_s,
      #       quantity: item.dig(:quantity)
      #     }
      #   end

      #   response[:phases] << new_phase
      # end

      response
    end

    def update_attributes_from_result(result)
      self.active                   = result.dig(:active).to_bool
      self.canceled_at              = result.dig(:canceled_at)
      self.client_id                = result.dig(:client_id)
      self.completed_at             = result.dig(:completed_at)
      self.current_phase            = result.dig(:current_phase)
      self.customer_id              = result.dig(:customer_id)
      self.end_behavior             = result.dig(:end_behavior)
      self.metadata                 = result.dig(:metadata).presence || {}
      self.phases                   = result.dig(:phases).presence || {}
      self.status                   = result.dig(:status)
      self.subscription_id          = result.dig(:subscription_id)
      self.subscription_schedule_id = result.dig(:subscription_schedule_id)

      true
    end
  end
end
