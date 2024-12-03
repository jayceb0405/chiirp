# frozen_string_literal: true

# app/controllers/users/notifications_controller.rb
module Users
  class NotificationsController < Users::UserController
    before_action :authenticate_user!
    before_action :authorize_user!
    before_action :user

    # (GET)
    # /users/notifications/:id/edit
    # edit_users_notification_path(:id)
    # edit_users_notification_url(:id)
    def edit
      respond_to do |format|
        format.js { render partial: 'users/js/show', locals: { cards: ['notifications'] } }
        format.html { render 'users/show', locals: { user_page_section: 'notifications' } }
      end
    end

    # (PUT/PATCH)
    # /users/notifications/:id
    # users_notification_path(:id)
    # users_notification_url(:id)
    def update
      @user.update(params_user)

      respond_to do |format|
        format.js { render partial: 'users/js/show', locals: { cards: ['notifications'] } }
        format.html { redirect_to root_path }
      end
    end

    private

    def authorize_user!
      super
      return if current_user.access_controller?('users', 'notifications', session)

      raise ExceptionHandlers::UserNotAuthorized.new('My Profile > Notifications', root_path)
    end
  end
end
