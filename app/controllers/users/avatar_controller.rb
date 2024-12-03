# frozen_string_literal: true

# app/controllers/users/avatar_controller.rb
module Users
  class AvatarController < Users::UserController
    before_action :authenticate_user!
    before_action :authorize_user!
    before_action :user

    # (PUT/PATCH)
    # /users/avatar/:id
    # users_avatar_path(:id)
    # users_avatar_url(:id)
    def update
      @user.avatar.purge
      @user.update(params.permit(:avatar))

      respond_to do |format|
        format.js { render partial: 'users/js/show', locals: { cards: ['profile_avatar'] } }
        format.html { redirect_to root_path }
      end
    end
  end
end
