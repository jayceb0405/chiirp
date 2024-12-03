# frozen_string_literal: true

# app/controllers/clients/kpis_controller.rb
module Clients
  # endpoints supporting general KPI actions
  class KpisController < Clients::ClientController
    before_action :authenticate_user!
    before_action :client
    before_action :authorize_user!
    before_action :kpi, only: %i[destroy edit update]

    # (POST)
    # /clients/kpis
    # clients_kpis_path
    # clients_kpis_url
    def create
      @kpi = current_user.client.client_kpis.create(kpi_params)

      cards = if @kpi.errors.any?
                %w[kpis kpis_edit kpis_show td_kpi_name]
              else
                %w[kpis]
              end

      respond_to do |format|
        format.js   { render partial: 'clients/js/show', locals: { cards: } }
        format.html { redirect_to root_path }
      end
    end

    # (DELETE)
    # /clients/kpis/:id
    # clients_kpi_path(:id)
    # clients_kpi_url(:id)
    def destroy
      @kpi.destroy
      @kpi = nil

      respond_to do |format|
        format.js   { render partial: 'clients/js/show', locals: { cards: %w[kpis] } }
        format.html { redirect_to root_path }
      end
    end

    # (GET)
    # /clients/kpis/:id/edit
    # edit_clients_kpi_path(, :id)
    # edit_clients_kpi_url(, :id)
    def edit
      respond_to do |format|
        format.js   { render partial: 'clients/js/show', locals: { cards: %w[kpis_edit] } }
        format.html { redirect_to root_path }
      end
    end

    # (GET) list all Client::Kpis
    # /clients/kpis
    # clients_kpis_path
    # clients_kpis_url
    def index
      respond_to do |format|
        format.js   { render partial: 'clients/js/show', locals: { cards: %w[kpis] } }
        format.html { render 'clients/show', locals: { client_page_section: 'kpis' } }
      end
    end

    # (GET)
    # /clients/kpis/new
    # new_clients_kpi_path
    # new_clients_kpi_url
    def new
      @kpi = current_user.client.client_kpis.new

      respond_to do |format|
        format.js   { render partial: 'clients/js/show', locals: { cards: %w[kpis kpis_edit kpis_show] } }
        format.html { redirect_to root_path }
      end
    end

    # (PUT/PATCH)
    # /clients/kpis/:id
    # _path(:id)
    # _url(:id)
    def update
      @kpi.update(kpi_params)

      respond_to do |format|
        format.js   { render partial: 'clients/js/show', locals: { cards: %w[kpis] } }
        format.html { redirect_to root_path }
      end
    end

    private

    def authorize_user!
      super

      return if current_user.access_controller?('clients', 'kpis', session)

      raise ExceptionHandlers::UserNotAuthorized.new('My Company Profile > KPIs', root_path)
    end

    def client
      @client = current_user.client
    end

    def kpi
      kpi_id = params.dig(:id).to_i

      if kpi_id.positive? && (@kpi = @client.client_kpis.find_by(id: kpi_id))
        true
      else
        sweetalert_error('Unathorized Access!', 'Your account could NOT be confirmed.', '', { persistent: 'OK' })

        respond_to do |format|
          format.js { render js: "window.location = '#{root_path}'" and return false }
          format.html { redirect_to root_path and return false }
        end
      end
    end

    def kpi_params
      params.require(:clients_kpi).permit(:name, :criteria_01, :c_01_in_period, :criteria_02, :c_02_in_period, :operator, :color)
    end
  end
end
