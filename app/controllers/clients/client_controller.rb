# frozen_string_literal: true

# app/controllers/clients/client_controller.rb
module Clients
  class ClientController < ApplicationController
    private

    def authorize_user!
      super
      return if current_user.team_member?
      return if @client && current_user.client_id == @client.id

      raise ExceptionHandlers::UserNotAuthorized.new('My Company Profile', root_path)
    end

    def client
      return if (@client = Client.find_by(id: params.permit(:client_id).dig(:client_id).to_i))

      sweetalert_error('Client NOT found!', 'We were not able to access the client you requested.', '', { persistent: 'OK' }) if current_user.team_member?

      respond_to do |format|
        format.js { render js: "window.location = '#{root_path}'" and return false }
        format.html { redirect_to root_path and return false }
      end
    end
  end
end
