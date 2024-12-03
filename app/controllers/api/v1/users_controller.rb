# frozen_string_literal: true

# app/controllers/api/v1/users_controller.rb
module Api
  module V1
    class UsersController < ApiController
      before_action -> { doorkeeper_authorize! :public }, only: [:index]

      before_action only: %i[create update destroy] do
        doorkeeper_authorize! :write
      end

      def index
        respond_with User.recent
      end

      def create
        respond_with 'api_v1', User.create!(params[:user])
      end
    end
  end
end
