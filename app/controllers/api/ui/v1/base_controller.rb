# frozen_string_literal: true

# app/controllers/api/ui/v1/base_controller.rb
module Api
  module Ui
    module V1
      class BaseController < ::ApplicationController
        rescue_from ActiveRecord::RecordNotFound, with: :not_found
        rescue_from ExceptionHandlers::UserNotAuthorized, with: :user_not_authorized

        skip_before_action :verify_authenticity_token
        before_action :authorize_user!

        def current_resource_owner
          @current_resource_owner ||= if doorkeeper_token&.acceptable?(:write)
                                        user = User.find(doorkeeper_token.resource_owner_id)
                                        user unless user.suspended?
                                      end
        end

        def current_user
          current_resource_owner
        end

        private

        def not_found
          head :not_found
        end

        def user_not_authorized
          head :unauthorized
        end
      end
    end
  end
end
