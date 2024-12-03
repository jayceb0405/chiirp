# frozen_string_literal: true

# app/controllers/clients/org_positions_controller.rb
module Clients
  # endpoints supporting general OrgPosition actions
  class OrgPositionsController < Clients::ClientController
    before_action :authenticate_user!
    before_action :client
    before_action :authorize_user!
    before_action :set_org_position, only: %w[destroy edit show update]

    # (POST) create a new OrgPosition
    # /client/:client_id/org_positions
    # client_org_positions_path(:client_id)
    # client_org_positions_url(:client_id)
    def create
      @client.org_positions.create(org_position_params)

      @org_positions       = @client.org_positions.order(:level)
      @org_users           = @client.org_users.where.not(org_group: 0).includes(:user)
      @org_groups          = @org_users.pluck(:org_group).uniq
      @available_org_users = OrgUser.available_org_users(@client)

      respond_to do |format|
        format.js { render partial: 'clients/js/show', locals: { cards: [20, 25, 30, 31] } }
        format.html { redirect_to client_org_positions_path(@client.id) }
      end
    end

    # (DELETE) delete a OrgPosition
    # /client/:client_id/org_positions/:id
    # client_org_position_path(:client_id, :id)
    # client_org_position_url(:client_id, :id)
    def destroy
      @org_position.destroy

      @org_positions       = @client.org_positions.order(:level)
      @org_users           = @client.org_users.where.not(org_group: 0).includes(:user)
      @org_groups          = @org_users.pluck(:org_group).uniq
      @available_org_users = OrgUser.available_org_users(@client)

      respond_to do |format|
        format.js { render partial: 'clients/js/show', locals: { cards: [20, 25, 30, 31] } }
        format.html { redirect_to client_org_positions_path(@client.id) }
      end
    end

    # (GET) edit a Client's OrgChart
    # /client/:client_id/org_positions/:id/edit
    # edit_client_org_position_path(:client_id, :id)
    # edit_client_org_position_url(:client_id, :id)
    def edit
      respond_to do |format|
        format.js { render partial: 'clients/js/show', locals: { cards: [22] } }
        format.html { redirect_to client_org_positions_path(@client.id) }
      end
    end

    # (GET) list OrgPositions
    # /client/:client_id/org_positions
    # client_org_positions_path(:client_id)
    # client_org_positions_url(:client_id)
    def index
      respond_to do |format|
        format.js   { render partial: 'clients/js/show', locals: { cards: [20] } }
        format.html { redirect_to client_org_positions_path(@client.id) }
      end
    end

    # (GET) create a new OrgPosition
    # /client/:client_id/org_positions/new
    # new_client_org_position_path(:client_id)
    # new_client_org_position_url(:client_id)
    def new
      @org_position = @client.org_positions.new

      respond_to do |format|
        format.js { render partial: 'clients/js/show', locals: { cards: [23] } }
        format.html { redirect_to client_org_positions_path(@client.id) }
      end
    end

    # (GET)
    # /client/:client_id/org_chart
    # client_org_chart_path(:client)
    # client_org_chart_url(:client_id)
    def org_chart
      respond_to do |format|
        format.js { render partial: 'clients/js/show', locals: { cards: ['org_chart'] } }
        format.html { render 'clients/show', locals: { client_page_section: 'org_chart' } }
      end
    end

    # (GET) show the OrgPositions
    # /client/:client_id/org_positions/:id
    # client_org_position_path(:client_id, :id)
    # client_org_position_url(:client_id, :id)
    def show
      respond_to do |format|
        format.js { render partial: 'clients/js/show', locals: { cards: [21] } }
        format.html { redirect_to client_org_positions_path(@client.id) }
      end
    end

    # (PUT/PATCH) update an existing OrgPosition
    # /client/:client_id/org_positions/:id
    # client_org_position_path(:client_id, :id)
    # client_org_position_url(:client_id, :id)
    def update
      commit = params.include?(:commit) ? params[:commit].to_s.downcase.tr(' ', '_') : ''

      case commit
      when 'save_positions'

        if org_position_order_params.to_h.length.positive? && (org_positions = @client.org_positions)

          org_positions.each do |org_position|
            org_position.update(level: org_position_order_params[org_position.id.to_s].to_i) if org_position_order_params.include?(org_position.id.to_s)
          end
        end
      else
        @org_position.update(org_position_params)
      end

      @org_positions       = @client.org_positions.order(:level)
      @org_users           = @client.org_users.where.not(org_group: 0).includes(:user)
      @org_groups          = @org_users.pluck(:org_group).uniq
      @available_org_users = OrgUser.available_org_users(@client)

      respond_to do |format|
        format.js { render partial: 'clients/js/show', locals: { cards: [20, 25, 30, 31] } }
        format.html { redirect_to client_org_positions_path(@client.id) }
      end
    end

    private

    def authorize_user!
      super

      return if current_user.access_controller?('clients', 'org_chart', session)

      raise ExceptionHandlers::UserNotAuthorized.new('My Company Profile > Org Charts', root_path)
    end

    def org_position_params
      response = params.require(:org_position).permit(:title, :client_custom_field_id)

      response[:client_custom_field_id] = response.dig(:client_custom_field_id).to_i

      response
    end

    def org_position_order_params
      params.require(:org_position).permit(params.include?(:org_position) ? params[:org_position].keys : '')
    end

    def set_org_position
      @org_position = nil

      @org_position = if @client && params.include?(:id)
                        if params[:id].to_i.positive?
                          @client.org_positions.find_by(id: params[:id].to_i)
                        else
                          @client.org_positions.new
                        end
                      else
                        @client.org_positions.new
                      end

      return if @org_position

      respond_to do |format|
        format.js { render js: "window.location = '#{root_path}'" and return false }
        format.html { redirect_to root_path and return false }
      end
    end
  end
end
