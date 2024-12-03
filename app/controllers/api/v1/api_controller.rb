# frozen_string_literal: true

# app/controllers/api/v1/api_controller.rb
module Api
  module V1
    class ApiController < ::ApplicationController
      def current_resource_owner
        User.find(doorkeeper_token.resource_owner_id) if doorkeeper_token
      end
    end
  end
end
