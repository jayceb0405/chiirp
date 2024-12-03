# frozen_string_literal: true

# app/controllers/users/admin_controller.rb
module Users
  # User admin screen endpoints
  class AdminController < Users::UserController
    before_action :authenticate_user!
    before_action :authorize_user!
    before_action :user

    # (GET)
    # /users/admin/:id/edit
    # edit_users_admin_path(:id)
    # edit_users_admin_url(:id)
    def edit
      respond_to do |format|
        format.js { render partial: 'users/js/show', locals: { cards: ['admin'] } }
        format.html { render 'users/show', locals: { user_page_section: 'admin' } }
      end
    end

    # (PUT/PATCH)
    # /users/admin/:id
    # users_admin_path(:id)
    # users_admin_url(:id)
    def update
      @user.update(params_user) if params.include?(:user)

      if params.dig('send-invite').to_bool
        @user.invite!(current_user)

        @user.delay(
          run_at:     Time.current,
          priority:   DelayedJob.job_priority('send_text'),
          queue:      DelayedJob.job_queue('send_text'),
          contact_id: 0,
          user_id:    @user.id,
          process:    'send_text'
        ).send_text(
          content:      "#{I18n.t('devise.text.invitation_instructions.hello').gsub('%{firstname}', @user.firstname)} - #{I18n.t('devise.text.invitation_instructions.someone_invited_you')} #{I18n.t('devise.text.invitation_instructions.accept')} #{accept_user_invitation_url(invitation_token: @user.raw_invitation_token)}",
          msg_type:     'textoutuser',
          sending_user: current_user
        )
      end

      respond_to do |format|
        format.js { render partial: 'users/js/show', locals: { cards: ['admin'] } }
        format.html { redirect_to root_path }
      end
    end

    private

    def authorize_user!
      super
      return if current_user.access_controller?('users', 'admin_settings', session)

      raise ExceptionHandlers::UserNotAuthorized.new('My Profile > Admin Settings', root_path)
    end
  end
end
