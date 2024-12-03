# frozen_string_literal: true

# app/controllers/clients/stages_controller.rb
module Clients
  # support for editing Stages
  class StagesController < Clients::ClientController
    before_action :authenticate_user!
    before_action :client
    before_action :set_stage_parent
    before_action :authorize_user!
    before_action :set_stage, only: %i[destroy edit update]

    # (POST)
    # /client/:client_id/stage_parents/:stage_parent_id/stages
    # client_stage_parent_stages_path(:client_id, :stage_parent_id)
    # client_stage_parent_stages_url(:client_id, :stage_parent_id)
    def create
      new_sort_order = @stage_parent.stages.any? ? @stage_parent.stages.order(:sort_order).last.sort_order + 1 : 0
      @stage_parent.stages.create(params_stage.merge({ sort_order: new_sort_order }))

      respond_to do |format|
        format.js   { render partial: 'clients/stage_parents/js/show', locals: { cards: %w[stage_index], stage_parent: @stage_parent } }
        format.html { redirect_to root_path }
      end
    end

    # (DELETE)
    # /client/:client_id/stage_parents/:stage_parent_id/stages/:id
    # client_stage_parent_stage_path(:client_id, :stage_parent_id, :id)
    # client_stage_parent_stage_url(:client_id, :stage_parent_id, :id)
    def destroy
      @stage.destroy
      remove_instance_variable(:@stage)

      respond_to do |format|
        format.js   { render partial: 'clients/stage_parents/js/show', locals: { cards: %w[stage_index], stage_parent: @stage_parent } }
        format.html { redirect_to root_path }
      end
    end

    # (GET)
    # /client/:client_id/stage_parents/:stage_parent_id/stages/:id/edit
    # edit_client_stage_parent_stage_path(:client_id, :stage_parent_id, :id)
    # edit_client_stage_parent_stage_url(:client_id, :stage_parent_id, :id)
    def edit
      respond_to do |format|
        format.js   { render partial: 'clients/stage_parents/js/show', locals: { cards: %w[stage_edit], stage_parent: @stage_parent, stage: @stage } }
        format.html { redirect_to root_path }
      end
    end

    # (GET)
    # /client/:client_id/stage_parents/:stage_parent_id/stages
    # client_stage_parent_stages_path(:client_id, :stage_parent_id)
    # client_stage_parent_stages_url(:client_id, :stage_parent_id)
    def index
      respond_to do |format|
        format.js   { render partial: 'clients/stage_parents/js/show', locals: { cards: %w[stage_index], stage_parent: @stage_parent } }
        format.html { redirect_to client_stage_parents_path(@client.id) }
      end
    end

    # (GET)
    # /client/:client_id/stage_parents/:stage_parent_id/stages/new
    # new_client_stage_parent_stage_path(:client_id, :stage_parent_id)
    # new_client_stage_parent_stage_url(:client_id, :stage_parent_id)
    def new
      stage = @stage_parent.stages.new(name: "New #{Stage.title}")

      respond_to do |format|
        format.js   { render partial: 'clients/stage_parents/js/show', locals: { cards: %w[stage_index], stage_parent: @stage_parent, stage: } }
        format.html { redirect_to root_path }
      end
    end

    # (PUT/PATCH)
    # /client/:client_id/stage_parents/:stage_parent_id/stages/:id
    # client_stage_parent_stage_path(:client_id, :stage_parent_id, :id)
    # client_stage_parent_stage_url(:client_id, :stage_parent_id, :id)
    def update
      @stage.update(params_stage)

      respond_to do |format|
        format.js   { render partial: 'clients/stage_parents/js/show', locals: { cards: %w[stage_edit stage_name], stage_parent: @stage_parent, stage: @stage } }
        format.html { redirect_to root_path }
      end
    end

    private

    def authorize_user!
      super
      return if current_user.access_controller?('clients', 'pipelines', session)

      raise ExceptionHandlers::UserNotAuthorized.new("My Company Profile > #{StageParent.title.pluralize}", root_path)
    end

    def params_stage
      response = params.require(:stage).permit(:name, :campaign_id, show_custom_fields: [])

      response[:name]               = response.dig(:name).to_s
      response[:campaign_id]        = response.dig(:campaign_id).to_i
      response[:show_custom_fields] = response.dig(:show_custom_fields).map(&:to_i)

      response
    end

    def set_stage
      stage_id = params.dig(:id).to_i

      if stage_id.positive? && (@stage = @stage_parent.stages.find_by(id: stage_id))
        true
      else
        sweetalert_error('Unathorized Access!', 'Your account could NOT be confirmed.', '', { persistent: 'OK' })

        respond_to do |format|
          format.js   { render js: "window.location = '#{root_path}'" and return false }
          format.html { redirect_to root_path and return false }
        end
      end
    end

    def set_stage_parent
      stage_parent_id = params.dig(:stage_parent_id).to_i

      if stage_parent_id.positive? && (@stage_parent = @client.stage_parents.find_by(id: stage_parent_id))
        true
      else
        sweetalert_error('Unathorized Access!', 'Your account could NOT be confirmed.', '', { persistent: 'OK' })

        respond_to do |format|
          format.js   { render js: "window.location = '#{root_path}'" and return false }
          format.html { redirect_to root_path and return false }
        end
      end
    end
  end
end
