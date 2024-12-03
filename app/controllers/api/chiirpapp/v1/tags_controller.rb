# frozen_string_literal: true

# app/controllers/api/chiirpapp/v1/tags_controller.rb
module Api
  module Chiirpapp
    module V1
      class TagsController < ChiirpappApiController
        # (POST) create a new Tag
        # /api/chiirpapp/v1/user/:user_id/tags
        # api_chiirpapp_v1_user_tags_path(:user_id)
        # api_chiirpapp_v1_user_tags_url(:user_id)
        def create
          sanitized_tag = params.permit(:tag).dig(:tag).to_s
          tag           = sanitized_tag.present? ? @user.client.tags.find_or_create_by!(name: sanitized_tag) : {}

          render json: tag.to_json, layout: false, status: (tag.present? ? :ok : :bad_request)
        end

        # (DELETE) delete a Tag
        # /api/chiirpapp/v1/user/:user_id/tags/:id
        # api_chiirpapp_v1_user_tag_path(:user_id, :id)
        # api_chiirpapp_v1_user_tag_url(:user_id, :id)
        def destroy
          @user.client.tags.find_by(id: params.dig(:id).to_i)&.destroy

          render json: {}, layout: false, status: :ok
        end

        # (GET) return all Tags for a Client
        # /api/chiirpapp/v1/user/:user_id/tags
        # api_chiirpapp_v1_user_tags_path(:user_id)
        # api_chiirpapp_v1_user_tags_url(:user_id)
        def index
          render json: @user.client.tags.to_json, layout: false, status: :ok
        end

        # (GET) return a Tag
        # /api/chiirpapp/v1/user/:user_id/tags/:id
        # api_chiirpapp_v1_user_tag_path(:user_id, :id)
        # api_chiirpapp_v1_user_tag_url(:user_id, :id)
        def show
          render json: @user.client.tags.find_by(id: params.dig(:id).to_i), layout: false, status: :ok
        end
      end
    end
  end
end
