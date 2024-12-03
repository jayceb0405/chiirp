# frozen_string_literal: true

# app/controllers/users/user_controller.rb
module Users
  class UserController < ApplicationController
    private

    def authorized?
      current_user.team_member? || current_user.id == @user.id ||
        (current_user.agent? && current_user.client.active? && (@user.nil? || @user.client.my_agencies.include?(current_user.client.id))) ||
        (current_user.admin? && current_user.client.active? && current_user.client.users.pluck(:id).include?(@user.id))
    end

    def params_user
      sanitized_params = params.require(:user).permit(
        :agent, :default_stage_parent_id, :incoming_call_popup, :phone_in, :phone_in_with_action, :phone_out, :ring_duration,
        :super_admin, :suspended_at, :team_member, notifications: [agency_clients: [], campaigns: %i[by_push by_text], review: %i[by_push by_text matched unmatched], task: %i[by_text by_push created updated due deadline completed],
        text: [:on_contact, { arrive: [] }]], trainings_editable: []
      )

      sanitized_params[:agent]                               = sanitized_params[:agent].to_bool if sanitized_params.dig(:agent)
      sanitized_params[:default_stage_parent_id]             = sanitized_params[:default_stage_parent_id].to_i if sanitized_params.dig(:default_stage_parent_id)
      sanitized_params[:incoming_call_popup]                 = sanitized_params[:incoming_call_popup].to_bool if sanitized_params.dig(:incoming_call_popup)
      sanitized_params[:phone_in_with_action]                = sanitized_params[:phone_in_with_action].to_bool if sanitized_params.dig(:phone_in_with_action)
      sanitized_params[:ring_duration]                       = sanitized_params[:ring_duration].to_i if sanitized_params.dig(:ring_duration)
      sanitized_params[:super_admin]                         = sanitized_params[:super_admin].to_bool if sanitized_params.dig(:super_admin)
      sanitized_params[:suspended_at]                        = if sanitized_params[:suspended_at].to_s.present?
                                                                 Time.use_zone(@client ? @client.time_zone : @user.client.time_zone) { Chronic.parse(sanitized_params[:suspended_at]) || sanitized_params[:suspended_at].to_time }&.utc
                                                               end
      sanitized_params[:team_member]                         = sanitized_params[:team_member].to_bool if sanitized_params.dig(:team_member)

      sanitized_params[:notifications][:agency_clients]      = sanitized_params[:notifications][:agency_clients].compact_blank.map(&:to_i) if sanitized_params.dig(:notifications, :agency_clients)

      sanitized_params[:notifications][:campaigns][:by_text] = sanitized_params[:notifications][:campaigns][:by_text].to_bool if sanitized_params.dig(:notifications, :campaigns, :by_text)
      sanitized_params[:notifications][:campaigns][:by_push] = sanitized_params[:notifications][:campaigns][:by_push].to_bool if sanitized_params.dig(:notifications, :campaigns, :by_push)

      sanitized_params[:notifications][:review][:matched]    = sanitized_params[:notifications][:review][:matched].to_bool if sanitized_params.dig(:notifications, :review, :matched)
      sanitized_params[:notifications][:review][:unmatched]  = sanitized_params[:notifications][:review][:unmatched].to_bool if sanitized_params.dig(:notifications, :review, :unmatched)
      sanitized_params[:notifications][:review][:by_text]    = sanitized_params[:notifications][:review][:by_text].to_bool if sanitized_params.dig(:notifications, :review, :by_text)
      sanitized_params[:notifications][:review][:by_push]    = sanitized_params[:notifications][:review][:by_push].to_bool if sanitized_params.dig(:notifications, :review, :by_push)

      sanitized_params[:notifications][:task][:by_push]      = sanitized_params[:notifications][:task][:by_push].to_bool if sanitized_params.dig(:notifications, :task, :by_push)
      sanitized_params[:notifications][:task][:by_text]      = sanitized_params[:notifications][:task][:by_text].to_bool if sanitized_params.dig(:notifications, :task, :by_text)
      sanitized_params[:notifications][:task][:created]      = sanitized_params[:notifications][:task][:created].to_bool if sanitized_params.dig(:notifications, :task, :created)
      sanitized_params[:notifications][:task][:updated]      = sanitized_params[:notifications][:task][:updated].to_bool if sanitized_params.dig(:notifications, :task, :updated)
      sanitized_params[:notifications][:task][:due]          = sanitized_params[:notifications][:task][:due].to_bool if sanitized_params.dig(:notifications, :task, :due)
      sanitized_params[:notifications][:task][:deadline]     = sanitized_params[:notifications][:task][:deadline].to_bool if sanitized_params.dig(:notifications, :task, :deadline)
      sanitized_params[:notifications][:task][:completed]    = sanitized_params[:notifications][:task][:completed].to_bool if sanitized_params.dig(:notifications, :task, :completed)

      sanitized_params[:notifications][:text][:arrive]       = sanitized_params[:notifications][:text][:arrive].compact_blank.map(&:to_i) if sanitized_params.dig(:notifications, :text, :arrive).is_a?(Array)
      sanitized_params[:notifications][:text][:on_contact]   = sanitized_params[:notifications][:text][:on_contact].to_bool if sanitized_params.dig(:notifications, :text, :on_contact)
      sanitized_params[:trainings_editable]                  = sanitized_params[:trainings_editable].compact_blank if sanitized_params.dig(:trainings_editable)

      sanitized_params.to_h
    end

    def user
      if (@user = User.find_by(id: params.dig(:id).to_i) || User.find_by(id: params.dig(:user_id).to_i))

        unless authorized?
          sweetalert_error('Unathorized Access!', 'You could NOT be authorized.', '', { persistent: 'OK' })
          @user = nil
        end
      else
        sweetalert_error('User NOT found!', 'We were not able to access the person you requested.', '', { persistent: 'OK' })
        @user = nil
      end

      return if @user

      respond_to do |format|
        format.js { render js: "window.location = '#{root_path}'" and return false }
        format.html { redirect_to root_path and return false }
      end
    end
  end
end
