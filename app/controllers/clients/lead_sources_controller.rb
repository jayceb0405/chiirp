# frozen_string_literal: true

# app/controllers/clients/lead_sources_controller.rb
module Clients
  # endpoints supporting Client Lead Sources
  class LeadSourcesController < Clients::ClientController
    before_action :authenticate_user!
    before_action :client
    before_action :authorize_user!
    before_action :lead_source, only: %i[destroy edit update]

    # (POST)
    # /client/:client_id/lead_sources
    # client_lead_sources_path(:client_id)
    # client_lead_sources_url(:client_id)
    def create
      @lead_source = current_user.client.lead_sources.create(params_lead_source)

      render partial: 'clients/lead_sources/js/show', locals: { cards: %w[index] }
    end

    # (DELETE)
    # /client/:client_id/lead_sources/:id
    # client_lead_source_path(:client_id, :id)
    # client_lead_source_url(:client_id, :id)
    def destroy
      @lead_source.destroy
      @lead_source = nil

      render partial: 'clients/lead_sources/js/show', locals: { cards: %w[index] }
    end

    # (GET)
    # /client/:client_id/lead_sources/:id/edit
    # edit_client_lead_source_path(:client_id, :id)
    # edit_client_lead_source_url(:client_id, :id)
    def edit
      render partial: 'clients/lead_sources/js/show', locals: { cards: %w[edit] }
    end

    # (GET)
    # /client/:client_id/lead_sources
    # client_lead_sources_path(:client_id)
    # client_lead_sources_url(:client_id)
    def index
      respond_to do |format|
        format.js   { render partial: 'clients/lead_sources/js/show', locals: { cards: %w[index] } }
        format.html { render 'clients/show', locals: { client_page_section: 'lead_sources' } }
      end
    end

    # (GET)
    # /client/:client_id/lead_sources/new
    # new_client_lead_source_path(:client_id)
    # new_client_lead_source_url(:client_id)
    def new
      @lead_source = current_user.client.lead_sources.create

      render partial: 'clients/lead_sources/js/show', locals: { cards: %w[new] }
    end

    # (PUT/PATCH)
    # /client/:client_id/lead_sources/:id
    # client_lead_source_path(:client_id, :id)
    # client_lead_source_url(:client_id, :id)
    def update
      @lead_source.update(params_lead_source)

      render partial: 'clients/lead_sources/js/show', locals: { cards: %w[index] }
    end

    private

    def authorize_user!
      super

      return if current_user.access_controller?('clients', 'lead_sources', session)

      raise ExceptionHandlers::UserNotAuthorized.new('My Company Profile > Lead Sources', root_path)
    end

    def params_lead_source
      params.require(:clients_lead_source).permit(:name)
    end

    def lead_source
      lead_source_id = params.permit(:id).dig(:id).to_i

      if lead_source_id.positive? && (@lead_source = @client.lead_sources.find_by(id: lead_source_id))
        true
      else
        sweetalert_error('Invalid Lead Source!', 'The requested lead source could not be found.', '', { persistent: 'OK' })

        respond_to do |format|
          format.js { render js: "window.location = '#{root_path}'" and return false }
          format.html { redirect_to root_path and return false }
        end
      end
    end
  end
end
