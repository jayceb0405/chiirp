# frozen_string_literal: true

# app/controllers/system_settings/versions_controller.rb
module SystemSettings
  # System Settings endpoints supporting Versioning
  class VersionsController < SystemSettings::SystemSettingsController
    before_action :set_version, only: %i[edit update]

    # (POST) create a new Version
    # /system_settings/versions
    # system_settings_versions_path
    # system_settings_versions_url
    def create
      @version = Version.create(version_params)

      respond_to do |format|
        format.js   { render partial: 'system_settings/js/show', locals: { cards: %w[version_index] } }
        format.html { redirect_to system_settings_path }
      end
    end

    # (GET) edit a Version
    # /system_settings/versions/:id/edit
    # edit_system_settings_version_path(:id)
    # edit_system_settings_version_url(:id)
    def edit
      respond_to do |format|
        format.js   { render partial: 'system_settings/js/show', locals: { cards: %w[version_edit] } }
        format.html { redirect_to system_settings_path }
      end
    end

    # (GET) show version history
    # /system_settings/versions/history
    # system_settings_version_history_path
    # system_settings_version_history_url
    def history
      offset = params.permit(:offset).dig(:offset).to_i

      current_user.update(version_notification: false)

      @versions = Version.order(start_date: :desc).offset(offset).limit(10)

      respond_to do |format|
        format.html { render 'system_settings/versions/history', locals: { offset: } }
        format.js   { render partial: 'system_settings/js/show', locals: { cards: %w[append_history], offset: } }
      end
    end

    # (GET) list system settings
    # /system_settings/versions
    # system_settings_versions_path
    # system_settings_versions_url
    def index
      @version = Version.new

      respond_to do |format|
        format.js   { render js: "window.location = '#{system_settings_path}'" }
        format.html { render 'system_settings/index' }
      end
    end

    # (GET)
    # /system_settings/versions/new
    # new_system_settings_version_path
    # new_system_settings_version_url
    def new
      @version = Version.new(header: 'New Version', start_date: Time.current)

      respond_to do |format|
        format.js   { render partial: 'system_settings/js/show', locals: { cards: %w[version_index] } }
        format.html { redirect_to system_settings_path }
      end
    end

    # (PATCH) update an existing Version
    # /system_settings/versions/:id
    # system_settings_version_path(:id)
    # system_settings_version_url(:id)
    def update
      @version.update(version_params)

      respond_to do |format|
        format.js   { render partial: 'system_settings/js/show', locals: { cards: %w[version_index] } }
        format.html { redirect_to system_settings_path }
      end
    end

    private

    def set_version
      @version = if params.include?(:id)
                   Version.find_by(id: params[:id].to_i)
                 else
                   Version.new
                 end
    end

    def version_params
      sanitized_params = params.require(:version).permit(:header, :description, :start_date)

      sanitized_params[:start_date] = Time.use_zone(I18n.t("tenant.#{Rails.env}.time_zone")) { Chronic.parse(sanitized_params[:start_date]) } unless sanitized_params[:start_date].empty?

      sanitized_params
    end
  end
end
