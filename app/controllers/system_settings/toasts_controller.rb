# frozen_string_literal: true

# app/controllers/system_settings/toasts_controller.rb
module SystemSettings
  # System Settings endpoints supporting User Toasts
  class ToastsController < SystemSettings::SystemSettingsController
    # (POST) send a Toast to all Users
    # /system_settings/toast
    # system_settings_toast_path
    # system_settings_toast_url
    def create
      User.delay(
        run_at:              Time.current,
        priority:            DelayedJob.job_priority('send_push'),
        queue:               DelayedJob.job_queue('send_push'),
        user_id:             current_user.id,
        contact_id:          0,
        triggeraction_id:    0,
        contact_campaign_id: 0,
        group_process:       0,
        process:             'send_push',
        data:                { content: toast_params.dig(:content).to_s }
      ).notify_all_users(target: %w[desktop mobile toast], content: toast_params.dig(:content))

      respond_to do |format|
        format.js   { render partial: 'system_settings/js/show', locals: { cards: %w[toasts_edit] } }
        format.html { redirect_to system_settings_path }
      end
    end

    # (GET) edit a Version
    # /system_settings/toast/edit
    # edit_system_settings_toast_path
    # edit_system_settings_toast_url
    def edit
      respond_to do |format|
        format.js   { render partial: 'system_settings/js/show', locals: { cards: %w[toasts_edit] } }
        format.html { redirect_to system_settings_path }
      end
    end

    private

    def toast_params
      params.permit(:content)
    end
  end
end
