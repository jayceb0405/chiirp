# frozen_string_literal: true

# app/controllers/clients/groups_controller.rb
module Clients
  class GroupsController < Clients::ClientController
    before_action :authenticate_user!
    before_action :client
    before_action :authorize_user!
    before_action :set_group, only: %i[destroy edit update]

    # (POST)
    # /client/:client_id/groups
    # client_groups_path(:client_id)
    # client_groups_url(:client_id)
    def create
      @group = current_user.client.groups.create(params_group)

      respond_to do |format|
        format.js   { render partial: 'clients/js/show', locals: { cards: %w[groups] } }
        format.html { redirect_to root_path }
      end
    end

    # (DELETE)
    # /client/:client_id/groups/:id
    # client_group_path(:client_id, :id)
    # client_group_url(:client_id, :id)
    def destroy
      @group.destroy
      @group = nil

      respond_to do |format|
        format.js   { render partial: 'clients/js/show', locals: { cards: %w[groups] } }
        format.html { redirect_to root_path }
      end
    end

    # (GET)
    # /client/:client_id/groups/:id/edit
    # edit_client_group_path(:client_id, :id)
    # edit_client_group_url(:client_id, :id)
    def edit
      respond_to do |format|
        format.js   { render partial: 'clients/js/show', locals: { cards: %w[groups_edit] } }
        format.html { redirect_to root_path }
      end
    end

    # (GET)
    # /client/:client_id/groups
    # client_groups_path(:client_id)
    # client_groups_url(:client_id)
    def index
      respond_to do |format|
        format.js   { render partial: 'clients/js/show', locals: { cards: %w[groups] } }
        format.html { render 'clients/show', locals: { client_page_section: 'groups' } }
      end
    end

    # (GET)
    # /client/:client_id/groups/new
    # new_client_group_path(:client_id)
    # new_client_group_url(:client_id)
    def new
      @group = current_user.client.groups.new

      respond_to do |format|
        format.js   { render partial: 'clients/js/show', locals: { cards: ['groups'] } }
        format.html { redirect_to root_path }
      end
    end

    # (PUT/PATCH)
    # /client/:client_id/groups/:id
    # client_group_path(:client_id, :id)
    # client_group_url(:client_id, :id)
    def update
      @group.update(params_group)

      respond_to do |format|
        format.js   { render partial: 'clients/js/show', locals: { cards: %w[groups_edit td_group_name] } }
        format.html { redirect_to root_path }
      end
    end

    private

    def authorize_user!
      super

      return if current_user.access_controller?('clients', 'groups', session)

      raise ExceptionHandlers::UserNotAuthorized.new('My Company Profile > Groups', root_path)
    end

    def params_group
      params.require(:group).permit(:name)
    end

    def set_group
      group_id = params.dig(:id).to_i

      if group_id.positive? && (@group = @client.groups.find_by(id: group_id))
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
