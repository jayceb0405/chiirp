# frozen_string_literal: true

# app/models/users/dashboards/dashboard.rb
module Users
  module Dashboards
    class Dashboard
      DASHBOARD_AUTOMATIONS_COLUMNS = [
        ['Last Started', 'last_started'],
        %w[Name name],
        %w[Strategy strategy],
        %w[Type type],
        %w[Status status],
        %w[Contacts contacts]
      ].freeze
      DYNAMIC_DATES_ARRAY = [
        %w[Today td],
        %w[Yesterday yd],
        ['This Week', 'tw'],
        ['Last Week', 'lw'],
        ['This Month', 'tm'],
        ['Last Month', 'lm'],
        ['Last 7 Days', 'l7'],
        ['Last 30 Days', 'l30'],
        ['Last 60 Days', 'l60'],
        ['Last 90 Days', 'l90'],
        ['This Year (to date)', 'tytd'],
        ['Last Year (to date)', 'lytd'],
        ['Last Year', 'ly']
      ].freeze

      # return Automations data for Dashboard
      # Users::Dashboards::Dashboard.new.automations()
      #   (req) user_settings: (Users::Setting)
      def automations(user_settings)
        date_range = Users::Dashboards::Dashboard.new.date_range(user_settings)

        if user_settings.data.dig(:user_ids).present?
          {
            page:          user_settings.data.dig(:automations, :page),
            page_size:     user_settings.data.dig(:automations, :page_size),
            total_results: Contacts::Campaign.campaigns_by_user(user_settings.data[:user_ids], date_range[0], date_range[1])
                                             .select('MAX(contact_campaigns.created_at) AS last_started, campaigns.name AS name, campaign_groups.name AS strategy, triggers.name AS type, contact_campaigns.completed AS completed, COUNT(contact_campaigns.id) AS contacts')
                                             .joins(:campaign)
                                             .joins(campaign: :campaign_group)
                                             .joins(campaign: :triggers)
                                             .where('triggers.step_numb = 1')
                                             .group('campaigns.name, campaign_groups.name, triggers.name, contact_campaigns.completed').length,
            results:       Contacts::Campaign.campaigns_by_user(user_settings.data[:user_ids], date_range[0], date_range[1])
                                             .select('MAX(contact_campaigns.created_at) AS last_started, campaigns.name AS name, campaign_groups.name AS strategy, triggers.name AS type, contact_campaigns.completed AS completed, COUNT(contact_campaigns.id) AS contacts')
                                             .joins(:campaign)
                                             .joins(campaign: :campaign_group)
                                             .joins(campaign: :triggers)
                                             .where('triggers.step_numb = 1')
                                             .group('campaigns.name, campaign_groups.name, triggers.name, contact_campaigns.completed')
                                             .limit(user_settings.data.dig(:automations, :page_size))
                                             .offset((user_settings.data.dig(:automations, :page) - 1) * user_settings.data.dig(:automations, :page_size))
                                             .order(user_settings.data.dig(:automations, :order_column) => user_settings.data.dig(:automations, :order_direction))
          }
        else
          {
            page:          user_settings.data.dig(:automations, :page),
            page_size:     user_settings.data.dig(:automations, :page_size),
            total_results: Contacts::Campaign.campaigns(client.id, date_range[0], date_range[1])
                                             .select('MAX(contact_campaigns.created_at) AS last_started, campaigns.name AS name, campaign_groups.name AS strategy, triggers.name AS type, contact_campaigns.completed AS completed, COUNT(contact_campaigns.id) AS contacts')
                                             .joins(:campaign)
                                             .joins(campaign: :campaign_group)
                                             .joins(campaign: :triggers)
                                             .where('triggers.step_numb = 1')
                                             .group('campaigns.name, campaign_groups.name, triggers.name, contact_campaigns.completed').length,
            results:       Contacts::Campaign.campaigns(client.id, date_range[0], date_range[1])
                                             .select('MAX(contact_campaigns.created_at) AS last_started, campaigns.name AS name, campaign_groups.name AS strategy, triggers.name AS type, contact_campaigns.completed AS completed, COUNT(contact_campaigns.id) AS contacts')
                                             .joins(:campaign)
                                             .joins(campaign: :campaign_group)
                                             .joins(campaign: :triggers)
                                             .where('triggers.step_numb = 1')
                                             .group('campaigns.name, campaign_groups.name, triggers.name, contact_campaigns.completed')
                                             .limit(user_settings.data.dig(:automations, :page_size))
                                             .offset((user_settings.data.dig(:automations, :page) - 1) * user_settings.data.dig(:automations, :page_size))
                                             .order(user_settings.data.dig(:automations, :order_column) => user_settings.data.dig(:automations, :order_direction))
          }
        end
      end

      # return Dashboard Button data for Dashboard
      # Users::Dashboards::Dashboard.new.dashboard_button()
      #   (req) name:          (String)
      #   (req) user_settings: (Users::Setting)
      def dashboard_button(name, user_settings)
        case name.split('_').first
        when 'messages'
          Users::Dashboards::Message.new.send(name, user_settings)
        end
      end

      # calculate a date range from User selected dynamic or static range
      # Users::Dashboards::Dashboard.new.date_range_calc()
      #   (req) time_zone: (String)
      #
      #   (req) dynamic: (String)
      #     ~ or ~
      #   (req) from:    (String)
      #   (req) to:      (String)
      def date_range_calc(**args)
        return [Time.current.beginning_of_day.utc, Time.current.end_of_day.utc] unless args.dig(:time_zone).present?
        return ApplicationRecord.dynamic_date_range(args[:time_zone], 'td') unless args.dig(:dynamic).present? || (args.dig(:from).present? && args.dig(:to).present?)

        if args.dig(:dynamic).present?
          ApplicationRecord.dynamic_date_range(args[:time_zone], args.dig(:dynamic))
        elsif args.dig(:from).present? && args.dig(:to).present?
          Time.zone = args[:time_zone].to_s
          [Time.zone.strptime(args[:from], '%m/%d/%Y %I:%M %p').utc, Time.zone.strptime(args[:to], '%m/%d/%Y %I:%M %p').utc]
        end
      end

      # calculate a date range from Users::Setting Dashboard data
      # Users::Dashboards::Dashboard.new.date_range()
      #   (req) user_settings: (Users::Setting)
      def date_range(user_settings)
        if user_settings.data.dig(:timeframe).is_a?(String) && Users::Dashboards::Dashboard::DYNAMIC_DATES_ARRAY.to_h.values.include?(user_settings.data[:timeframe])
          date_range_calc(time_zone: user_settings.user.client.time_zone, dynamic: user_settings.data[:timeframe])
        elsif user_settings.data.dig(:timeframe).is_a?(Array)
          date_range_calc(time_zone: user_settings.user.client.time_zone, from: user_settings.data[:timeframe][0], to: user_settings.data[:timeframe][1])
        else
          date_range_calc(time_zone: user_settings.user.client.time_zone, dynamic: 'td')
        end
      end
    end
  end
end
