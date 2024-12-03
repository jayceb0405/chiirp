# frozen_string_literal: true

# app/controllers/users/overview_controller.rb
module Users
  class OverviewController < Users::UserController
    before_action :authenticate_user!
    before_action :authorize_user!
    before_action :user

    # (GET)
    # /users/overview/:id/edit
    # edit_users_overview_path(:id)
    # edit_users_overview_url(:id)
    def edit
      respond_to do |format|
        format.js { render partial: 'users/js/show', locals: { cards: ['overview'] } }
        format.html { render 'users/show', locals: { user_page_section: 'overview' } }
      end
    end
  end
end
