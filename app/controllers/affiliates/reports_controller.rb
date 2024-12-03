# frozen_string_literal: true

# app/controllers/affiliates/affiliates_controller.rb
module Affiliates
  class ReportsController < ApplicationController
    before_action :authenticate_user!
    before_action :authorize_user!

    # (GET) list Affiliate Reports
    # /affiliates/reports
    # affiliates_reports_path
    # affiliates_reports_url
    def index
      sanitized_params = params.permit(:commit, :include_setup_fees, :affiliate_id, :report_period_string)

      @report_period_string = sanitized_params.dig(:report_period_string) || "#{Date.current.beginning_of_month.strftime('%m/%d/%Y')} to #{Date.current.end_of_month.strftime('%m/%d/%Y')}"
      @include_setup_fees   = sanitized_params.dig(:include_setup_fees).to_bool

      case sanitized_params.dig(:affiliate_id).to_i
      when (1..)
        @affiliate = Affiliates::Affiliate.find_by(id: sanitized_params[:affiliate_id].to_i)
        @clients = Client.where(affiliate_id: @affiliate.id).joins(:client_transactions).where(client_transactions: { setting_key: %w[mo_charge startup_costs], created_at: (Chronic.parse(@report_period_string.split(' to ').first).beginning_of_day..Chronic.parse(@report_period_string.split(' to ').last).end_of_day) }).group(:id)
        @client_startup_costs = ClientTransaction.where(client_id: @clients).select(:client_id, 'sum(setting_value::float) as charge').where(setting_key: 'startup_costs', created_at: (Chronic.parse(@report_period_string.split(' to ').first).beginning_of_day..Chronic.parse(@report_period_string.split(' to ').last).end_of_day)).group(:client_id)
        @client_mo_charges    = ClientTransaction.where(client_id: @clients).select(:client_id, 'sum(setting_value::float) as charge').where(setting_key: 'mo_charge', created_at: (Chronic.parse(@report_period_string.split(' to ').first).beginning_of_day..Chronic.parse(@report_period_string.split(' to ').last).end_of_day)).group(:client_id)
      when -1
        @affiliate = Affiliates::Affiliate.new(id: -1)
        @clients = Client.with_integration_allowed('searchlight').joins(:client_transactions).where(client_transactions: { setting_key: %w[mo_charge startup_costs], created_at: (Chronic.parse(@report_period_string.split(' to ').first).beginning_of_day..Chronic.parse(@report_period_string.split(' to ').last).end_of_day) }).group(:id)
      when -2
        @affiliate = Affiliates::Affiliate.new(id: -2)
        @clients = PaymentTransaction.joins('LEFT OUTER JOIN clients ON clients.id = payment_transactions.client_id').group('payment_transactions.client_id, clients.name').select('payment_transactions.client_id as id, clients.name as name, SUM(payment_transactions.amount_total) as amount_total, SUM(payment_transactions.amount_requested) as amount_requested, SUM(payment_transactions.amount_fees) as amount_fees').where(payment_transactions: { target: %w[cardx], transacted_at: (Chronic.parse(@report_period_string.split(' to ').first).beginning_of_day..Chronic.parse(@report_period_string.split(' to ').last).end_of_day) })
      else
        @affiliate = nil
        @clients = []
      end

      respond_to do |format|
        format.js { render partial: 'affiliates/js/show', locals: { cards: %w[affiliates_report_index] } }

        case @affiliate&.id
        when (1..)
          format.html { render 'affiliates/reports/affiliate/printable', layout: 'printable' }
        when -1
          format.html { render 'affiliates/reports/searchlight/printable', layout: 'printable' }
        when -2
          format.html { render 'affiliates/reports/cardx/printable', layout: 'printable' }
        end
      end
    end

    private

    def authorize_user!
      super

      return if current_user.super_admin?

      raise ExceptionHandlers::UserNotAuthorized.new('Affiliates', root_path)
    end
  end
end
