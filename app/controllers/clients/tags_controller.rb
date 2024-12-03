# frozen_string_literal: true

# app/controllers/clients/tags_controller.rb
module Clients
  # support for editing Client Tags
  class TagsController < Clients::ClientController
    before_action :authenticate_user!
    before_action :client
    before_action :authorize_user!
    before_action :tag, only: %i[destroy edit update]

    # (POST)
    # /client/:client_id/tags
    # client_tags_path(:client_id)
    # client_tags_url(:client_id)
    def create
      @tag = current_user.client.tags.create(params_tag)

      respond_to do |format|
        format.js   { render partial: 'clients/js/show', locals: { cards: %w[tags] } }
        format.html { redirect_to root_path }
      end
    end

    # (DELETE)
    # /client/:client_id/tags/:id
    # client_tag_path(:client_id, :id)
    # client_tag_url(:client_id, :id)
    def destroy
      @tag.destroy
      @tag = nil

      respond_to do |format|
        format.js   { render partial: 'clients/js/show', locals: { cards: %w[tags] } }
        format.html { redirect_to root_path }
      end
    end

    # (GET)
    # /client/:client_id/tags/:id/edit
    # edit_client_tag_path(:client_id, :id)
    # edit_client_tag_url(:client_id, :id)
    def edit
      respond_to do |format|
        format.js   { render partial: 'clients/js/show', locals: { cards: %w[tags_edit] } }
        format.html { render 'clients/show', locals: { client_page_section: 'tags' } }
      end
    end

    # (GET)
    # /client/:client_id/tags
    # client_tags_path(:client_id)
    # client_tags_url(:client_id)
    def index
      respond_to do |format|
        format.js   { render partial: 'clients/js/show', locals: { cards: %w[tags] } }
        format.html { render 'clients/show', locals: { client_page_section: 'tags' } }
      end
    end

    # (GET)
    # /client/:client_id/tags/new
    # new_client_tag_path(:client_id)
    # new_client_tag_url(:client_id)
    def new
      @tag = current_user.client.tags.new

      respond_to do |format|
        format.js   { render partial: 'clients/js/show', locals: { cards: %w[tags] } }
        format.html { redirect_to root_path }
      end
    end

    # (PUT/PATCH)
    # /client/:client_id/tags/:id
    # client_tag_path(:client_id, :id)
    # client_tag_url(:client_id, :id)
    def update
      @tag.update(params_tag)

      respond_to do |format|
        format.js   { render partial: 'clients/js/show', locals: { cards: %w[tags_edit td_tag_name] } }
        format.html { redirect_to root_path }
      end
    end

    private

    def authorize_user!
      super
      return if current_user.access_controller?('clients', 'tags', session)

      raise ExceptionHandlers::UserNotAuthorized.new('My Company Profile > Tags', root_path)
    end

    def params_tag
      response = params.require(:tag).permit(:name, :campaign_id, :group_id, :tag_id, :stage_id, :color, stop_campaign_ids: [])

      response[:campaign_id]       = response.dig(:campaign_id).to_i
      response[:group_id]          = response.dig(:group_id).to_i
      response[:stage_id]          = response.dig(:stage_id).to_i
      response[:tag_id]            = response.dig(:tag_id).to_i
      response[:stop_campaign_ids] = response.dig(:stop_campaign_ids).compact_blank
      response[:stop_campaign_ids] = [0] if response.dig(:stop_campaign_ids).include?('0')

      response
    end

    def tag
      tag_id = params.dig(:id).to_i

      if tag_id.positive? && (@tag = @client.tags.find_by(id: tag_id))
        true
      else
        sweetalert_error('Unathorized Access!', 'Your account could NOT be confirmed.', '', { persistent: 'OK' })

        respond_to do |format|
          format.js { render js: "window.location = '#{root_path}'" and return false }
          format.html { redirect_to root_path and return false }
        end
      end
    end
  end
end
