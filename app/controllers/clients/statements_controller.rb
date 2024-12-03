# frozen_string_literal: true

# app/controllers/clients/statements_controller.rb
module Clients
  class StatementsController < Clients::ClientController
    before_action :authenticate_user!
    before_action :client, only: %i[show print]
    before_action :authorize_user!
    before_action :statement_params, only: %i[show print]

    # (GET) get a Client statement
    # /clients/statements/:client_id
    # clients_statement_path(:client_id)
    # clients_statement_url(:client_id)
    def show
      respond_to do |format|
        if @transaction_type.present?
          format.js { render partial: 'clients/js/show', locals: { cards: %w[index_transactions] } }
        else
          format.js { render partial: 'clients/js/show', locals: { cards: %w[show_statements] } }
        end

        format.html { render 'clients/show', locals: { client_page_section: 'statements' } }
      end
    end

    # (GET) print a Client statement
    # /clients/statements/:statement_client_id/print
    # clients_statement_print_path(:client_id)
    # clients_statement_print_url(:client_id)
    def print
      respond_to do |format|
        format.html { render 'clients/statements/printable', layout: 'printable' }
      end
    end

    private

    def authorize_user!
      super
      return if current_user.access_controller?('clients', 'statements', session)

      raise ExceptionHandlers::UserNotAuthorized.new('My Company Profile > Statements', root_path)
    end

    def statement_params
      @statement_month  = params.permit(:statement_month).dig(:statement_month).to_s
      @transaction_type = params.permit(:transaction_type).dig(:transaction_type).to_s
    end
  end
end
