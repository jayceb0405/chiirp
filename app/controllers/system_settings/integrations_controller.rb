# frozen_string_literal: true

# app/controllers/system_settings/integrations_controller.rb
module SystemSettings
  class IntegrationsController < SystemSettings::SystemSettingsController
    before_action :integration, only: %i[destroy edit logo_upload new update]

    # (PATCH) save new integrations arrangment
    # /system_settings/integrations/arrangement
    # system_settings_integration_arrangement_path
    # system_settings_integration_arrangement_url
    def arrangement
      arrange_integrations

      render js: 'success', layout: false, status: :ok
    end

    # (POST) save a new Integration
    # /system_settings/integrations
    # system_settings_integrations_path
    # system_settings_integrations_url
    def create
      Integration.create(params_integration)

      render partial: 'system_settings/js/show', locals: { cards: %w[integrations_index] }
    end

    # (DELETE) destroy an Integration
    # /system_settings/integrations/:id
    # system_settings_integration_path(:id)
    # system_settings_integration_url(:id)
    def destroy
      @integration.destroy

      render partial: 'system_settings/js/show', locals: { cards: %w[integrations_index] }
    end

    # (GET) edit an Integration
    # /system_settings/integrations/:id/edit
    # edit_system_settings_integration_path(:id)
    # edit_system_settings_integration_url(:id)
    def edit
      respond_to do |format|
        format.js   { render partial: 'system_settings/js/show', locals: { cards: %w[integration_edit] } }
        format.html { render 'system_settings/index', locals: { nav_item: 'integrations_edit', integration_id: @integration.id } }
      end
    end

    # (PATCH) upload a file to Cloudinary for an Integration
    # /system_settings/integrations/:id/logo_upload
    # system_settings_integration_logo_upload_path(:id)
    # system_settings_integration_logo_upload_url(:id)
    def logo_upload
      @integration.logo_image.purge
      @integration.update(params.permit(:logo_image))

      render partial: 'system_settings/js/show', locals: { cards: %w[integration_edit] }
    end

    # (GET) list Integrations
    # /system_settings/integrations
    # system_settings_integrations_path
    # system_settings_integrations_url
    def index
      render partial: 'system_settings/js/show', locals: { cards: %w[integrations_index] }
    end

    # (GET) start new Integration
    # /system_settings/integrations/new
    # new_system_settings_integration_path
    # new_system_settings_integration_url
    def new
      render partial: 'system_settings/js/show', locals: { cards: %w[integration_new] }
    end

    # (PUT/PATCH) update an Integration
    # /system_settings/integrations/:id
    # system_settings_integration_path(:id)
    # system_settings_integration_url(:id)
    def update
      @integration.update(params_integration)

      render partial: 'system_settings/js/show', locals: { cards: %w[integrations_index] }
    end

    private

    def arrange_integrations
      sanitized_sort_order = (params.permit(integration_buttons: []).dig(:integration_buttons) || []).map(&:to_i)

      SystemSettings::Integration.transaction do
        SystemSettings::Integration.find_each do |integration|
          integration.update(sort_order: sanitized_sort_order.find_index(integration.id))
        end
      end
    end

    def integration
      @integration = if params.dig(:id).to_i.positive?
                       SystemSettings::Integration.find_by(id: params.dig(:id).to_i)
                     else
                       SystemSettings::Integration.new
                     end
    end

    def params_integration
      sanitized_params = params.require(:system_settings_integration).permit(:company_name, :contact, :description, :image_url, :phone_number, :preferred, :short_description, :show_company_name, :website_url, :youtube_url)

      sanitized_params[:preferred]         = sanitized_params.dig(:preferred).to_bool
      sanitized_params[:show_company_name] = sanitized_params.dig(:show_company_name).to_bool

      sanitized_params
    end
  end
end
