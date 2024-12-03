# frozen_string_literal: true

# app/controllers/clients/features_controller.rb
module Clients
  class TaskActionsController < Clients::ClientController
    before_action :authenticate_user!
    before_action :client, only: %i[edit update]
    before_action :authorize_user!

    # (GET)
    # /clients/task_actions/:client_id/edit
    # edit_clients_task_action_path(:client_id)
    # edit_clients_task_action_url(:client_id)
    def edit
      respond_to do |format|
        format.js   { render partial: 'clients/js/show', locals: { cards: %w[task_actions] } }
        format.html { render 'clients/show', locals: { client_page_section: 'task_actions' } }
      end
    end

    # (PUT/PATCH)
    # /clients/task_actions/:client_id
    # clients_task_action_path(:client_id)
    # clients_task_action_url(:client_id)
    def update
      @client.update(params_task_actions)

      respond_to do |format|
        format.js   { render partial: 'clients/js/show', locals: { cards: %w[task_actions] } }
        format.html { redirect_to edit_clients_task_action_path(@client.id) }
      end
    end

    private

    def authorize_user!
      super

      return if current_user.access_controller?('clients', 'task_actions', session)

      raise ExceptionHandlers::UserNotAuthorized.new('My Company Profile > Task Actions', root_path)
    end

    def params_task_actions
      response = {}
      response[:task_actions] = @client.task_actions
      task_actions            = params.require(:client).permit({ task_actions: [assigned: %i[campaign_id group_id tag_id stage_id] + [{ stop_campaign_ids: [] }], due: %i[campaign_id group_id tag_id stage_id] + [{ stop_campaign_ids: [] }], deadline: %i[campaign_id group_id tag_id stage_id] + [{ stop_campaign_ids: [] }], completed: %i[campaign_id group_id tag_id stage_id] + [{ stop_campaign_ids: [] }]] })

      response[:task_actions]['assigned']['campaign_id']        = task_actions[:task_actions][:assigned][:campaign_id].to_i unless task_actions.dig(:task_actions, :assigned, :campaign_id).nil?
      response[:task_actions]['assigned']['group_id']           = task_actions[:task_actions][:assigned][:group_id].to_i unless task_actions.dig(:task_actions, :assigned, :group_id).nil?
      response[:task_actions]['assigned']['tag_id']             = task_actions[:task_actions][:assigned][:tag_id].to_i unless task_actions.dig(:task_actions, :assigned, :tag_id).nil?
      response[:task_actions]['assigned']['stage_id']           = task_actions[:task_actions][:assigned][:stage_id].to_i unless task_actions.dig(:task_actions, :assigned, :stage_id).nil?
      response[:task_actions]['assigned']['stop_campaign_ids']  = task_actions[:task_actions][:assigned][:stop_campaign_ids].compact_blank unless task_actions.dig(:task_actions, :assigned, :stop_campaign_ids).nil?
      response[:task_actions]['assigned']['stop_campaign_ids']  = [0] if response[:task_actions]['assigned']['stop_campaign_ids']&.include?('0')
      response[:task_actions]['due']['campaign_id']             = task_actions[:task_actions][:due][:campaign_id].to_i unless task_actions.dig(:task_actions, :due, :campaign_id).nil?
      response[:task_actions]['due']['group_id']                = task_actions[:task_actions][:due][:group_id].to_i unless task_actions.dig(:task_actions, :due, :group_id).nil?
      response[:task_actions]['due']['tag_id']                  = task_actions[:task_actions][:due][:tag_id].to_i unless task_actions.dig(:task_actions, :due, :tag_id).nil?
      response[:task_actions]['due']['stage_id']                = task_actions[:task_actions][:due][:stage_id].to_i unless task_actions.dig(:task_actions, :due, :stage_id).nil?
      response[:task_actions]['due']['stop_campaign_ids']       = task_actions[:task_actions][:due][:stop_campaign_ids].compact_blank unless task_actions.dig(:task_actions, :due, :stop_campaign_ids).nil?
      response[:task_actions]['due']['stop_campaign_ids']       = [0] if response[:task_actions]['due']['stop_campaign_ids']&.include?('0')
      response[:task_actions]['deadline']['campaign_id']        = task_actions[:task_actions][:deadline][:campaign_id].to_i unless task_actions.dig(:task_actions, :deadline, :campaign_id).nil?
      response[:task_actions]['deadline']['group_id']           = task_actions[:task_actions][:deadline][:group_id].to_i unless task_actions.dig(:task_actions, :deadline, :group_id).nil?
      response[:task_actions]['deadline']['tag_id']             = task_actions[:task_actions][:deadline][:tag_id].to_i unless task_actions.dig(:task_actions, :deadline, :tag_id).nil?
      response[:task_actions]['deadline']['stage_id']           = task_actions[:task_actions][:deadline][:stage_id].to_i unless task_actions.dig(:task_actions, :deadline, :stage_id).nil?
      response[:task_actions]['deadline']['stop_campaign_ids']  = task_actions[:task_actions][:deadline][:stop_campaign_ids].compact_blank unless task_actions.dig(:task_actions, :deadline, :stop_campaign_ids).nil?
      response[:task_actions]['deadline']['stop_campaign_ids']  = [0] if response[:task_actions]['deadline']['stop_campaign_ids']&.include?('0')
      response[:task_actions]['completed']['campaign_id']       = task_actions[:task_actions][:completed][:campaign_id].to_i unless task_actions.dig(:task_actions, :completed, :campaign_id).nil?
      response[:task_actions]['completed']['group_id']          = task_actions[:task_actions][:completed][:group_id].to_i unless task_actions.dig(:task_actions, :completed, :group_id).nil?
      response[:task_actions]['completed']['tag_id']            = task_actions[:task_actions][:completed][:tag_id].to_i unless task_actions.dig(:task_actions, :completed, :tag_id).nil?
      response[:task_actions]['completed']['stage_id']          = task_actions[:task_actions][:completed][:stage_id].to_i unless task_actions.dig(:task_actions, :completed, :stage_id).nil?
      response[:task_actions]['completed']['stop_campaign_ids'] = task_actions[:task_actions][:completed][:stop_campaign_ids].compact_blank unless task_actions.dig(:task_actions, :completed, :stop_campaign_ids).nil?
      response[:task_actions]['completed']['stop_campaign_ids'] = [0] if response[:task_actions]['completed']['stop_campaign_ids']&.include?('0')

      response
    end
  end
end
