# frozen_string_literal: true

# app/controllers/clients/dlc10/base_controller.rb
module Clients
  module Dlc10
    class BaseController < Clients::ClientController
      before_action :authenticate_user!
      before_action :client
      before_action :authorize_user!

      def dlc10_version
        'v2'
      end

      private

      def authorize_user!
        super
        return if current_user.access_controller?('clients', 'dlc10', session)

        raise ExceptionHandlers::UserNotAuthorized.new('My Company Profile > 10DLC', root_path)
      end
    end
  end
end
