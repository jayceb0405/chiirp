# frozen_string_literal: true

# app/controllers/clients/admin_controller.rb
module Clients
  class AdminController < Clients::ClientController
    before_action :authenticate_user!
    before_action :client
    before_action :authorize_user!

    def edit
      # (GET)
      # /clients/admin/:id/edit
      # edit_clients_admin_path(:id)
      # edit_clients_admin_url(:id)
      respond_to do |format|
        format.js { render partial: 'clients/js/show', locals: { cards: %w[admin] } }
        format.html { render 'clients/show', locals: { client_page_section: 'admin' } }
      end
    end

    def update
      # (PUT/PATCH)
      # /clients/admin/:id
      # clients_admin_path(:id)
      # clients_admin_url(:id)
      @client.update(client_params)

      respond_to do |format|
        format.js { render partial: 'clients/js/show', locals: { cards: %w[admin] } }
        format.html { redirect_to root_path }
      end
    end
  end
end
