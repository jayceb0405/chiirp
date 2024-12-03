# frozen_string_literal: true

# app/controllers/clients/terms_controller.rb
module Clients
  class TermsController < Clients::ClientController
    before_action :authenticate_user!
    before_action :client
    before_action :authorize_user!

    # (GET)
    # /clients/terms/:id
    # edit_clients_term_path(:id)
    # edit_clients_term_url(:id)
    def edit
      show = params.dig(:show).to_bool

      if @client.terms_accepted.to_s.empty? || show
        # terms & conditions have NOT been accepted

        respond_to do |format|
          format.js   { render partial: 'clients/js/show', locals: { cards: %w[terms] } }
          format.html { render 'clients/show', locals: { client_page_section: 'terms' } }
        end
      else
        # terms & conditions have been accepted

        respond_to do |format|
          format.js   { render js: "window.location = '#{root_path}'" }
          format.html { redirect_to root_path }
        end
      end
    end

    # (PATCH/PUT)
    # /clients/terms/:id
    # clients_term_path(:id)
    # clients_term_url(:id)
    def update
      destination = (params.dig(:dest) || 'dashboard').to_s

      @client.update(terms_accepted: Time.current.iso8601) unless params.dig(:commit).to_s.casecmp?('print')

      respond_to do |format|
        if params.dig(:commit).to_s.casecmp?('print')
          format.js { render partial: 'clients/js/show', locals: { cards: %w[print_terms] } }
        elsif destination == 'client'
          format.js { render partial: 'clients/js/show', locals: { cards: %w[terms] } }
        else
          format.js { render js: "window.location = '#{root_path}'" }
        end

        format.html { redirect_to root_path }
      end
    end

    private

    def authorize_user!
      super
      return if current_user.access_controller?('clients', 'terms', session)

      raise ExceptionHandlers::UserNotAuthorized.new('My Company Profile > Terms', root_path)
    end
  end
end
