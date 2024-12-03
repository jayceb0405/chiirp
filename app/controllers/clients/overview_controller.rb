# frozen_string_literal: true

# app/controllers/users/overview_controller.rb
module Clients
  class OverviewController < Clients::ClientController
    before_action :authenticate_user!
    before_action :client
    before_action :authorize_user!

    # (GET)
    # /clients/overview/:id/edit
    # edit_clients_overview_path(:id)
    # edit_clients_overview_url(:id)
    def edit
      respond_to do |format|
        format.js { render partial: 'clients/js/show', locals: { cards: ['overview'] } }
        format.html { render 'clients/show', locals: { client_page_section: 'overview' } }
      end
    end
  end
end
