# frozen_string_literal: true

# app/controllers/clients/profile_controller.rb
module Clients
  class ProfileController < Clients::ClientController
    before_action :authenticate_user!
    before_action :client
    before_action :authorize_user!

    # (GET)
    # /clients/profile/:id/edit
    # edit_clients_profile_path(:id)
    # edit_clients_profile_url(:id)
    def edit
      respond_to do |format|
        format.js { render partial: 'clients/js/show', locals: { cards: ['profile'] } }
        format.html { render 'clients/show', locals: { client_page_section: 'profile' } }
      end
    end

    # (PUT/PATCH)
    # /clients/profile/:id
    # clients_profile_path(:id)
    # clients_profile_url(:id)
    def update
      @client.update(client_params)

      respond_to do |format|
        format.js { render partial: 'clients/js/show', locals: { cards: ['profile'] } }
        format.html { redirect_to root_path }
      end
    end

    # (PATCH) post Client data to Vitally
    # /clients/profile/update_vitally/:client_id
    # clients_profile_update_vitally_path(:client_id)
    # clients_profile_update_vitally_url(:client_id)
    def update_vitally
      vt_model = Integration::Vitally::V2024::Base.new
      vt_model.client_push(@client.id)

      @client.errors.add('client:', vt_model.message) unless vt_model.success?
    end

    private

    def authorize_user!
      super
      return if current_user.access_controller?('clients', 'profile', session)

      raise ExceptionHandlers::UserNotAuthorized.new('My Company Profile > Profile', root_path)
    end

    def client_params
      params.require(:client).permit(:address1, :address2, :city, :name, :phone, :state, :zip)
    end
  end
end
