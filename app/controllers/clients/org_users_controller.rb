# frozen_string_literal: true

# app/controllers/clients/org_users_controller.rb
module Clients
  # endpoints supporting general OrgUsersPosition actions
  class OrgUsersController < Clients::ClientController
    before_action :authenticate_user!
    before_action :client
    before_action :authorize_user!
    before_action :set_org_user, only: %i[destroy edit update]

    # (POST) create a new OrgUser
    # /client/:client_id/org_users
    # client_org_users_path(:client_id)
    # client_org_users_url(:client_id)
    def create
      @client.org_users.create(org_user_params)

      @org_positions       = @client.org_positions.order(:level)
      @org_users           = @client.org_users.where.not(org_group: 0).includes(:user)
      @org_groups          = @org_users.pluck(:org_group).uniq
      @available_org_users = OrgUser.available_org_users(@client)

      respond_to do |format|
        format.js { render partial: 'clients/js/show', locals: { cards: [30, 31, 35] } }
        format.html { redirect_to client_org_positions_path(@client.id) }
      end
    end

    # (DELETE) delete a OrgUser
    # /client/:client_id/org_users/:id
    # client_org_user_path(:client_id, :id)
    # client_org_user_url(:client_id, :id)
    def destroy
      @org_user&.destroy

      @org_positions       = @client.org_positions.order(:level)
      @org_users           = @client.org_users.where.not(org_group: 0).includes(:user)
      @org_groups          = @org_users.pluck(:org_group).uniq
      @available_org_users = OrgUser.available_org_users(@client)

      respond_to do |format|
        format.js { render partial: 'clients/js/show', locals: { cards: [30, 31] } }
        format.html { redirect_to client_org_positions_path(@client.id) }
      end
    end

    # (GET) edit a Client's OrgChart
    # /client/:client_id/org_users/:id/edit
    # edit_client_org_user_path(:client_id, :id)
    # edit_client_org_user_url(:client_id, :id)
    def edit
      respond_to do |format|
        format.js { render partial: 'clients/js/show', locals: { cards: [32] } }
        format.html { redirect_to client_org_positions_path(@client.id) }
      end
    end

    # (GET) list OrgUsers
    # /client/:client_id/org_users
    # client_org_users_path(:client_id)
    # client_org_users_url(:client_id)
    def index
      @org_positions       = @client.org_positions.order(:level)
      @org_users           = @client.org_users.where.not(org_group: 0).includes(:user)
      @org_groups          = @org_users.pluck(:org_group).uniq
      @available_org_users = OrgUser.available_org_users(@client)

      respond_to do |format|
        format.js { render partial: 'clients/js/show', locals: { cards: [30, 31] } }
        format.html { redirect_to client_org_positions_path(@client.id) }
      end
    end

    # (GET) create a new OrgGroup or OrgUser
    # /client/:client_id/org_users/new
    # new_client_org_user_path(:client_id)
    # new_client_org_user_url(:client_id)
    def new
      commit = params.dig(:commit).to_s.downcase

      case commit
      when 'add_org_group'
        @org_positions = @client.org_positions.order(:level)
        @org_users     = @client.org_users.where.not(org_group: 0).includes(:user)
        @org_groups    = [0] + @org_users.pluck(:org_group).uniq

        respond_to do |format|
          format.js { render partial: 'clients/js/show', locals: { cards: [31] } }
          format.html { redirect_to client_org_positions_path(@client.id) }
        end
      when 'add_org_user'
        @org_user = @client.org_users.new

        respond_to do |format|
          format.js { render partial: 'clients/js/show', locals: { cards: [33] } }
          format.html { redirect_to client_org_positions_path(@client.id) }
        end
      end
    end

    # (PUT/PATCH) update an existing OrgUser
    # /client/:client_id/org_users/:id
    # client_org_user_path(:client_id, :id)
    # client_org_user_url(:client_id, :id)
    def update
      commit = params.include?(:commit) ? params[:commit].to_s.downcase.tr(' ', '_') : ''

      case commit
      when 'save_organizations'
        organization = params[:organization] ? params.require(:organization).permit(params[:organization].keys) : {}

        # if a new OrgGroup was received define a new id for it
        new_org_group_id = (@client.org_users.pluck(:org_group) + [0]).max + 1 if organization.to_h.filter_map { |key, _value| key[0, 12] == 'orgposition_' ? key.split('_')[1].to_i : nil }.include?(0)

        current_group_id = 0
        current_org_position_id = 0

        organization.each do |key, _value|
          if key[0, 12] == 'orgposition_'
            current_group_id = key.split('_')[1].to_i
            current_group_id = new_org_group_id unless current_group_id.positive?
            current_org_position_id = key.split('_')[2].to_i
            @client.org_users.where(org_group: current_group_id, org_position_id: current_org_position_id).where.not(user_id: 0).destroy_all
            # rubocop:disable Rails/SkipsModelValidations
            @client.org_users.where(org_group: current_group_id, org_position_id: current_org_position_id).update_all(org_group: 0, org_position_id: 0)
            # rubocop:enable Rails/SkipsModelValidations
          elsif key[0, 5] == 'user_'
            @client.org_users.create(user_id: key.split('_')[1].to_i, org_group: current_group_id, org_position_id: current_org_position_id)
          elsif key[0, 8] == 'orguser_' && (org_user = @client.org_users.find_by(id: key.split('_')[1].to_i))
            org_user.update(org_group: current_group_id, org_position_id: current_org_position_id)
          end
        end
      when 'save'
        @org_user.update(org_user_params)
      end

      @org_positions       = @client.org_positions.order(:level)
      @org_users           = @client.org_users.where.not(org_group: 0).includes(:user)
      @org_groups          = @org_users.pluck(:org_group).uniq
      @available_org_users = OrgUser.available_org_users(@client)

      respond_to do |format|
        format.js { render partial: 'clients/js/show', locals: { cards: [30, 31, 35] } }
        format.html { redirect_to client_org_positions_path(@client.id) }
      end
    end

    private

    def authorize_user!
      super

      return if current_user.access_controller?('clients', 'org_chart', session)

      raise ExceptionHandlers::UserNotAuthorized.new('My Company Profile > Org Charts', root_path)
    end

    def org_user_params
      params.require(:org_user).permit(:firstname, :lastname, :phone, :email)
    end

    def set_org_user
      @org_user = @client.org_users.find_by(id: params[:id].to_i) if @client && params.include?(:id)
    end
  end
end
