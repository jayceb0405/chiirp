# frozen_string_literal: true

# app/controllers/registrations_controller.rb
class RegistrationsController < Devise::RegistrationsController
  protected

  def after_update_path_for(_resource)
    root_path
  end

  private

  def sign_up_params
    params.require(:user).permit(:firstname, :lastname, :phone, :email, :client_id, :password, :password_confirmation)
  end

  def account_update_params
    params.require(:user).permit(:firstname, :lastname, :phone, :email, :client_id, :password, :password_confirmation, :current_password)
  end
end
