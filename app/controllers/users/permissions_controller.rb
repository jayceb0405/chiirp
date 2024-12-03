# frozen_string_literal: true

# app/controllers/users/permissions_controller.rb
module Users
  class PermissionsController < Users::UserController
    before_action :authenticate_user!
    before_action :authorize_user!
    before_action :user

    # (GET)
    # /users/permissions/:id/edit
    # edit_users_permission_path(:id)
    # edit_users_permission_url(:id)
    def edit
      respond_to do |format|
        format.js { render partial: 'users/js/show', locals: { cards: ['permissions'] } }
        format.html { render 'users/show', locals: { user_page_section: 'permissions' } }
      end
    end

    # (PUT/PATCH)
    # /users/permissions/:id
    # users_permission_path(:id)
    # users_permission_url(:id)
    def update
      @user.update(params_permissions)

      respond_to do |format|
        format.js { render partial: 'users/js/show', locals: { cards: ['permissions'] } }
        format.html { redirect_to root_path }
      end
    end

    private

    def authorize_user!
      super

      return if current_user.access_controller?('users', 'permissions', session)

      raise ExceptionHandlers::UserNotAuthorized.new('My Profile > Permissions', root_path)
    end

    def params_permissions
      sanitized_params = params.require(:user).permit(aiagents_controller: [], campaigns_controller: [], central_controller: [], clients_controller: [], companies_controller: [], dashboard_controller: [], email_templates_controller: [], import_contacts_controller: [],
                                                      integrations_controller: [], integrations_servicetitan_controller: [], my_contacts_controller: [], stages_controller: [],
                                                      surveys_controller: [], trackable_links_controller: [], trainings_controller: [], user_contact_forms_controller: [], users_controller: [], widgets_controller: [])

      sanitized_params[:aiagents_controller]                  = sanitized_params[:aiagents_controller].compact_blank if sanitized_params.dig(:aiagents_controller)
      sanitized_params[:campaigns_controller]                 = sanitized_params[:campaigns_controller].compact_blank if sanitized_params.dig(:campaigns_controller)
      sanitized_params[:central_controller]                   = sanitized_params[:central_controller].compact_blank if sanitized_params.dig(:central_controller)
      sanitized_params[:clients_controller]                   = sanitized_params[:clients_controller].compact_blank if sanitized_params.dig(:clients_controller)
      sanitized_params[:companies_controller]                 = sanitized_params[:companies_controller].compact_blank if sanitized_params.dig(:companies_controller)
      sanitized_params[:dashboard_controller]                 = sanitized_params[:dashboard_controller].compact_blank if sanitized_params.dig(:dashboard_controller)
      sanitized_params[:email_templates_controller]           = sanitized_params[:email_templates_controller].compact_blank if sanitized_params.dig(:email_templates_controller)
      sanitized_params[:import_contacts_controller]           = sanitized_params[:import_contacts_controller].compact_blank if sanitized_params.dig(:import_contacts_controller)
      sanitized_params[:integrations_controller]              = sanitized_params[:integrations_controller].compact_blank if sanitized_params.dig(:integrations_controller)
      sanitized_params[:integrations_servicetitan_controller] = sanitized_params[:integrations_servicetitan_controller].compact_blank if sanitized_params.dig(:integrations_servicetitan_controller)
      sanitized_params[:my_contacts_controller]               = sanitized_params[:my_contacts_controller].compact_blank if sanitized_params.dig(:my_contacts_controller)
      sanitized_params[:stages_controller]                    = sanitized_params[:stages_controller].compact_blank if sanitized_params.dig(:stages_controller)
      sanitized_params[:surveys_controller]                   = sanitized_params[:surveys_controller].compact_blank if sanitized_params.dig(:surveys_controller)
      sanitized_params[:trackable_links_controller]           = sanitized_params[:trackable_links_controller].compact_blank if sanitized_params.dig(:trackable_links_controller)
      sanitized_params[:trainings_controller]                 = sanitized_params[:trainings_controller].compact_blank if sanitized_params.dig(:trainings_controller)
      sanitized_params[:user_contact_forms_controller]        = sanitized_params[:user_contact_forms_controller].compact_blank if sanitized_params.dig(:user_contact_forms_controller)
      sanitized_params[:users_controller]                     = sanitized_params[:users_controller].compact_blank if sanitized_params.dig(:users_controller)
      sanitized_params[:widgets_controller]                   = sanitized_params[:widgets_controller].compact_blank if sanitized_params.dig(:widgets_controller)

      sanitized_params
    end
  end
end
