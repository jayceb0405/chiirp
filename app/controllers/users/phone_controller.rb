# frozen_string_literal: true

# app/controllers/users/phone_controller.rb
module Users
  class PhoneController < Users::UserController
    before_action :authenticate_user!
    before_action :authorize_user!
    before_action :user

    # (GET)
    # /users/phone/:id/edit
    # edit_users_phone_path(:id)
    # edit_users_phone_url(:id)
    def edit
      respond_to do |format|
        format.js { render partial: 'users/js/show', locals: { cards: ['phone'] } }
        format.html { render 'users/show', locals: { user_page_section: 'phone' } }
      end
    end

    # (PUT/PATCH)
    # /users/phone/:id
    # users_phone_path(:id)
    # users_phone_url(:id)
    def update
      @user.update(params_user)

      respond_to do |format|
        format.js { render partial: 'users/js/show', locals: { cards: ['phone'] } }
        format.html { redirect_to root_path }
      end
    end

    private

    def authorize_user!
      super
      return if current_user.access_controller?('users', 'phone_processing', session)

      raise ExceptionHandlers::UserNotAuthorized.new('My Profile > Phone Processing', root_path)
    end
  end
end
