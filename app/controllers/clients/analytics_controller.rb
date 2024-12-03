# frozen_string_literal: true

# app/controllers/clients/analytics_controller.rb
module Clients
  class AnalyticsController < Clients::ClientController
    before_action :authenticate_user!
    before_action :authorize_user!

    def show
      # (GET) show Chiirp Analytics
      #
      # Example:
      #   /clients/analytics
      #   clients_analytics_path
      #   clients_analytics_url
      #
      # Required Parameters:
      #   none
      #
      # Optional Parameters:
      #   none
      #
      render 'clients/analytics/show'
    end

    def edit
      # (GET) display
      #
      # Example:
      #   /clients/analytics/edit
      #   edit_clients_analytics_path
      #   edit_clients_analytics_url
      #
      # Required Parameters:
      #   none
      #
      # Optional Parameters:
      #   month:      (Integer)
      #   year:       (Integer)
      #   show:       (String)
      #
      month = (params.dig(:month) || Time.current.month).to_i
      year  = (params.dig(:year) || Time.current.year).to_i
      show  = params.dig(:show).to_s.downcase

      cards = case show
              when 'new_clients_startup'
                [2]
              when 'new_clients_ad_costs'
                [3]
              when 'new_clients_commissions'
                [4]
              when 'new_leads_startup'
                [5]
              when 'new_leads_ad_costs'
                [6]
              when 'new_clients_leads'
                [7]
              when 'startup_costs'
                [8]
              when 'revenue_costs'
                [9]
              when 'new_clients_startup_ratio'
                [22]
              when 'new_clients_ad_costs_ratio'
                [23]
              when 'new_clients_commissions_ratio'
                [24]
              when 'new_leads_startup_ratio'
                [25]
              when 'new_leads_ad_costs_ratio'
                [26]
              when 'new_clients_leads_ratio'
                [27]
              when 'startup_costs_ratio'
                [28]
              when 'revenue_costs_ratio'
                [29]
              else
                [1]
              end

      respond_to do |format|
        format.js   { render partial: 'clients/analytics/js/show', locals: { cards:, month:, year: } }
        format.html { redirect_to clients_companies_path }
      end
    end

    def update
      # (PUT/PATCH) save costs
      #
      # Example:
      #   /clients/analytics/update
      #   clients_analytics_path
      #   clients_analytics_url
      #
      # Required Parameters:
      #   none
      #
      # Optional Parameters:
      #   none
      #
      month = (params.dig(:month) || Time.current.month).to_i
      year  = (params.dig(:year) || Time.current.year).to_i

      costs = params.require(:costs).permit(:ads, :commission_mid, :commission_end)

      tenant_cost = TenantCost.find_or_initialize_by(tenant: I18n.t('tenant.id'), month:, year:, cost_key: 'ads')
      tenant_cost.update(cost_value: costs.dig(:ads).to_d)

      tenant_cost = TenantCost.find_or_initialize_by(tenant: I18n.t('tenant.id'), month:, year:, cost_key: 'mid_comm')
      tenant_cost.update(cost_value: costs.dig(:commission_mid).to_d)

      tenant_cost = TenantCost.find_or_initialize_by(tenant: I18n.t('tenant.id'), month:, year:, cost_key: 'end_comm')
      tenant_cost.update(cost_value: costs.dig(:commission_end).to_d)

      respond_to do |format|
        format.js   { render partial: 'clients/analytics/js/show', locals: { cards: [1], month:, year: } }
        format.html { redirect_to clients_companies_path }
      end
    end

    private

    def authorize_user!
      super

      return if current_user.team_member?

      raise ExceptionHandlers::UserNotAuthorized.new('Analytics', root_path)
    end
  end
end
