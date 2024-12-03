# frozen_string_literal: true

module Integrations
  module Email
    module V1
      class StatsController < Integrations::Email::V1::IntegrationsController
        # (GET) Email stats screen
        # /integrations/email/v1/stats
        # integrations_email_v1_stats_path
        # integrations_email_v1_stats_url
        def show
          em_model = Integration::Email::V1::Base.new(@client_api_integration)
          return head(:unauthorized) unless em_model.connected?

          em_client = Integrations::EMail::V1::Base.new(@client_api_integration.username, Rails.application.credentials[:sendgrid][:chiirp], current_user.client_id)
          @reputation = em_client.reputation
          @stats      = format_stats(em_client.stats(aggregated_by: 'day', start_date: 30.days.ago.to_date))
          @requests   = @stats.find { |stat| stat[:name] == 'Requests' }&.dig(:data)&.values&.sum.to_i
          @opens      = @stats.find { |stat| stat[:name] == 'Opens' }&.dig(:data)&.values&.sum.to_i
          @bounces    = @stats.find { |stat| stat[:name] == 'Bounces' }&.dig(:data)&.values&.sum.to_i
          @clicks     = @stats.find { |stat| stat[:name] == 'Unique Clicks' }&.dig(:data)&.values&.sum.to_i

          render partial: 'integrations/email/v1/js/show', locals: { cards: %w[stats] }
        end

        private

        def format_stats(stats)
          # stats.map { |data| { name: data[:date], data: data.dig(:stats, 0, :metrics) } }
          data = Hash.new { |hash, key| hash[key] = {} }
          stats.each do |stat|
            next if Date.parse(stat[:date]).future?

            stat.dig(:stats, 0, :metrics).each do |name, value|
              data[name][stat[:date]] = value
            end
          end
          data.map do |name, value|
            { name: name.to_s.titleize, data: value }
          end
        end
      end
    end
  end
end

# example return from em_client.stats
# [
#   {
#     "date": "2023-11-01",
#     "stats": [
#       {
#         "type": "subuser",
#         "name": "sg-chiirp-client-1",
#         "metrics": {
#           "blocks": 0,
#           "bounce_drops": 0,
#           "bounces": 0,
#           "clicks": 0,
#           "deferred": 0,
#           "delivered": 1,
#           "invalid_emails": 0,
#           "opens": 1,
#           "processed": 1,
#           "requests": 1,
#           "spam_report_drops": 0,
#           "spam_reports": 0,
#           "unique_clicks": 0,
#           "unique_opens": 1,
#           "unsubscribe_drops": 0,
#           "unsubscribes": 0
#         }
#       }
#     ]
#   },
#   {
#     "date": "2023-12-01",
#     "stats": [
#       {
#         "type": "subuser",
#         "name": "sg-chiirp-client-1",
#         "metrics": {
#           "blocks": 0,
#           "bounce_drops": 4,
#           "bounces": 2,
#           "clicks": 0,
#           "deferred": 0,
#           "delivered": 12,
#           "invalid_emails": 0,
#           "opens": 1,
#           "processed": 14,
#           "requests": 18,
#           "spam_report_drops": 0,
#           "spam_reports": 0,
#           "unique_clicks": 0,
#           "unique_opens": 1,
#           "unsubscribe_drops": 0,
#           "unsubscribes": 0
#         }
#       }
#     ]
#   }
# ]
