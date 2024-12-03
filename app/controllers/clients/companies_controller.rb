# frozen_string_literal: true

# app/controllers/clients/companies_controller.rb
module Clients
  class CompaniesController < ApplicationController
    before_action :authenticate_user!
    before_action :authorize_user!
    before_action :user_settings

    # (GET) list Clients (Companies)
    # /clients/companies
    # clients_companies_path
    # clients_companies_url
    def index
      list_type = params.dig(:list_type) || 'clients'

      @user_settings.update(data: params_user_settings)

      respond_to do |format|
        format.js   { render partial: 'clients/companies/js/show', locals: { cards: %w[index], list_type: } }
        format.html { render 'clients/companies/index', locals: { list_type: } }
      end
    end

    private

    def authorize_user!
      super

      return if current_user.access_controller?('companies', 'allowed', session)

      raise ExceptionHandlers::UserNotAuthorized.new('Companies', root_path)
    end

    def params_user_settings
      sanitized_params = params.permit(:per_page, :page, :active_only, :in_danger, :delinquent_only, :paying_only, :search_text, :search_period)

      response                   = {}
      response[:per_page]        = (sanitized_params.dig(:per_page) || @user_settings.data.dig(:per_page)).to_i
      response[:page]            = (sanitized_params.dig(:page) || @user_settings.data.dig(:page)).to_i
      response[:active_only]     = (sanitized_params.dig(:active_only) || @user_settings.data.dig(:active_only)).to_bool
      response[:in_danger]       = (sanitized_params.dig(:in_danger) || @user_settings.data.dig(:in_danger)).to_bool
      response[:delinquent_only] = (sanitized_params.dig(:delinquent_only) || @user_settings.data.dig(:delinquent_only)).to_bool
      response[:paying_only]     = (sanitized_params.dig(:paying_only) || @user_settings.data.dig(:paying_only)).to_bool
      response[:search_text]     = (sanitized_params.dig(:search_text) || @user_settings.data.dig(:search_text)).to_s
      response[:search_period]   = (sanitized_params.dig(:search_period) || @user_settings.data.dig(:search_period)).to_s

      response
    end

    def user_settings
      @user_settings = current_user.user_settings.find_or_initialize_by(controller_action: 'clients_index', current: 1)
      user_settings_initialize if @user_settings.new_record?
    end

    def user_settings_initialize
      @user_settings.update(data: {
                              per_page:      25,
                              page:          1,
                              active_only:   false,
                              in_danger:     false,
                              search_text:   '',
                              search_period: "#{Time.now.utc.beginning_of_month.strftime('%m/%d/%Y')} to #{Time.now.utc.end_of_month.strftime('%m/%d/%Y')}"
                            })
    end
  end
end
