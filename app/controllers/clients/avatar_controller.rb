# frozen_string_literal: true

# app/controllers/clients/avatar_controller.rb
module Clients
  class AvatarController < Clients::ClientController
    before_action :authenticate_user!
    before_action :client
    before_action :authorize_user!

    def update
      # (PUT/PATCH)
      # /clients/avatar/:id
      # clients_avatar_path(:id)
      # clients_avatar_url(:id)
      @client.logo_image.purge
      @client.update(params.permit(:logo_image))

      respond_to do |format|
        format.js { render partial: 'clients/js/show', locals: { cards: ['profile_avatar'] } }
        format.html { redirect_to root_path }
      end
    end
  end
end
