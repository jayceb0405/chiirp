# frozen_string_literal: true

module Users
  class SessionsController < Devise::SessionsController
    skip_before_action :set_session_vars, only: %i[create]
    skip_before_action :redis_controller_action, only: %i[create]

    # GET /resource/sign_in
    # def new
    #   super
    # end

    # POST /resource/sign_in
    def create
      user = User.find_for_authentication(email: sign_in_params[:email])

      valid = user&.valid_password?(sign_in_params[:password]) && user.valid_for_authentication?
      Users::SignInDebug.create(email: sign_in_params[:email], commit: params[:commit], remote_ip: request.remote_ip, user_agent: request.user_agent, user:, user_signed_in?: valid.to_bool)

      # redirect if account is locked out
      return redirect_to(new_user_session_path, alert: t('devise.failure.locked')) if user&.access_locked?

      unless valid
        # log the failed attempt
        user&.increment_failed_attempts
        if user&.send(:attempts_exceeded?)
          user.lock_access!
          return redirect_to(new_user_session_path, alert: t('devise.failure.locked'))
        end

        # send user to try again if password was incorrect
        return redirect_to(new_user_session_path, alert: t('devise.failure.invalid'))
      end

      # #####################
      # Password was correct
      # #####################

      # set otp_user_id session to be used on 2FA page
      session[:otp_user_id] = user.id

      # redirect to 2FA selection page
      redirect_to method_user_two_factor_path
    end

    # DELETE /resource/sign_out
    # def destroy
    #   super
    # end

    # protected

    # If you have extra params to permit, append them to the sanitizer.
    # def configure_sign_in_params
    #   devise_parameter_sanitizer.permit(:sign_in, keys: [:attribute])
    # end
  end
end
