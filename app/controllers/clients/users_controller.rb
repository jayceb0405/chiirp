# frozen_string_literal: true

# app/controllers/users/admin_controller.rb
module Clients
  class UsersController < Clients::ClientController
    before_action :authenticate_user!
    before_action :client
    before_action :authorize_user!
    before_action :user, only: %i[destroy edit update update_vitally]

    # (POST)
    # /client/:client_id/users
    # client_users_path(:client_id)
    # client_users_url(:client_id)
    def create
      @user = @client.users.new(params_user)
      @user.skip_password_validation = true
      @user.save

      if !@user.new_record? && params.dig('send-invite').to_bool
        @user.invite!(current_user)

        @user.delay(
          run_at:   Time.current,
          priority: 0,
          process:  'send_text'
        ).send_text(
          content:  "#{I18n.t('devise.text.invitation_instructions.hello').gsub('%{firstname}', @user.firstname)} - #{I18n.t('devise.text.invitation_instructions.someone_invited_you')} #{I18n.t('devise.text.invitation_instructions.accept')} #{accept_user_invitation_url(invitation_token: @user.raw_invitation_token)}",
          msg_type: 'textoutuser'
        )
      end

      @user.assign_to_all_client_phone_numbers! if !@user.new_record? && params.dig(:user, :all_phone_numbers).to_bool

      respond_to do |format|
        format.html { render 'users/show', locals: { user_page_section: 'profile' } }
      end
    end

    # (DELETE)
    #  /client/:client_id/users/:id
    #  client_user_path(:client_id, :id)
    #  client_user_url(:client_id, :id)
    def destroy
      @user.destroy
    end

    # (GET)
    # /client/:client_id/users/:id/edit
    # edit_client_user_path(:client_id, :id)
    # edit_client_user_url(:client_id, :id)
    def edit
      respond_to do |format|
        format.turbo_stream { render 'clients/users/edit' }
        format.html { render 'users/show', locals: { user_page_section: 'profile' } }
      end
    end

    # (GET)
    # /client/:client_id/users
    # client_users_path(:client_id)
    # client_users_url(:client_id)
    def index
      respond_to do |format|
        format.turbo_stream { render 'clients/users/index' }
        format.html { render 'clients/show', locals: { client_page_section: 'users' } }
      end
    end

    # (GET)
    # /client/:client_id/users/new
    # new_client_user_path(:client_id)
    # new_client_user_url(:client_id)
    def new
      @user = @client.users.new

      respond_to do |format|
        format.turbo_stream { render 'clients/users/new' }
        format.html { render 'users/show', locals: { user_page_section: 'profile' } }
      end
    end

    # (PUT/PATCH)
    # /client/:client_id/users/:id
    # client_user_path(:client_id, :id)
    # client_user_url(:client_id, :id)
    def update
      @user.update(params_user)

      return unless current_user.super_admin? && params.dig(:user, :locked).present?

      return if params.dig(:user, :locked).to_bool

      @user.locked_at.present? && @user.unlock_access!
    end

    # (PATCH) post User data to Vitally
    # /client/:client_id/users/:id/update_vitally
    # client_users_update_vitally_path(:client_id, :id)
    # client_users_update_vitally_url(:client_id, :id)
    # /users/profile/update_vitally/:user_id
    # users_profile_update_vitally_path(:user_id)
    # users_profile_update_vitally_url(:user_id)
    def update_vitally
      vt_model = Integration::Vitally::V2024::Base.new
      vt_model.user_push(@user.id)

      @user.errors.add('user:', vt_model.message) unless vt_model.success?
    end

    private

    def authorize_user!
      super

      return if current_user.access_controller?('clients', 'users', session)

      raise ExceptionHandlers::UserNotAuthorized.new('My Company Profile > Users', root_path)
    end

    def params_user
      sanitized_params = params.require(:user).permit(:firstname, :lastname, :phone, :email, :ext_ref_id, :submit_text_on_enter).to_h

      sanitized_params[:submit_text_on_enter] = sanitized_params[:submit_text_on_enter].to_bool if sanitized_params.dig(:submit_text_on_enter)

      sanitized_params
    end

    def user
      @user = if params.dig(:id).to_i.zero?
                @client.users.new
              else
                @client.users.find_by(id: params.dig(:id).to_i)
              end

      return if @user

      sweetalert_error('User NOT found!', 'We were not able to access the User you requested.', '', { persistent: 'OK' })

      respond_to do |format|
        format.js { render js: "window.location = '#{client_users_path(@client.id)}'" and return false }
        format.html { redirect_to client_users_path(@client.id) and return false }
      end
    end
  end
end
