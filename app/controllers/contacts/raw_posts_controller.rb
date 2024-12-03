# frozen_string_literal: true

# app/controllers/integrations/servicetitan/integrations_controller.rb
module Contacts
  class RawPostsController < ApplicationController
    before_action :authenticate_user!
    before_action :authorize_user!

    def index
      @contact = Contact.find(params[:contact_id])
      @raw_posts = @contact.raw_posts.order(created_at: :desc)
    end

    def show
      @raw_post = Contacts::RawPost.find(params[:id])

      respond_to do |format|
        format.js
        format.json { render json: @raw_post.attributes.to_json }
        format.html
      end
    end

    private

    def authorize_user!
      super
      return if current_user.team_member? || current_user.agency_user_logged_in_as(session).team_member?

      raise ExceptionHandlers::UserNotAuthorized.new('RawPosts', root_path)
    end
  end
end
