# frozen_string_literal: true

module Users
  class TwoFactorController < ActionController::Base # rubocop:disable Rails/ApplicationController
    TWO_FACTOR_SMS_PHONE = '8018556779'

    layout 'devise'

    before_action :verify_session_otp_user_id!
    before_action :find_user

    def new
      redirect_to(new_user_session_path) if @user.nil? || user_signed_in?
    end

    def attempt
      redirect_to method_user_two_factor_path if session[:otp_method].nil?
    end

    def method
      method = params[:user][:otp_method]

      # create 2FA secret & code time
      @user.update!(
        invitation_created_at:  nil,
        invitation_accepted_at: nil,
        invitation_sent_at:     nil,
        otp_secret:             ROTP::Base32.random,
        otp_secret_at:          Time.now.utc.to_i
      )

      case method
      when 'sms'
        SMS::Bandwidth.send(TWO_FACTOR_SMS_PHONE, @user.phone, "Your Chiirp authentication code is: #{@user.otp_code}", [], 'chiirp', true)
      when 'email'
        UserMailer.with(user_id: @user.id).two_factor_authentication.deliver_now
      else
        flash.alert = t('devise.failure.invalid_otp_method')
        return redirect_to method_user_two_factor_path
      end

      session[:otp_method] = method

      # redirect to 2FA page
      redirect_to attempt_user_two_factor_path
    end

    def create
      location = if @user&.otp_code_valid?(params[:user][:otp_attempt]&.strip)
                   sign_in(:user, @user)
                   session[:sign_in_at] = Time.now.to_i
                   after_sign_in_path_for(@user)
                 else
                   # mark failed attempts
                   @user.increment_failed_attempts
                   if @user.send(:attempts_exceeded?)
                     @user.lock_access!
                     flash.alert = t('devise.failure.locked')
                   else
                     flash.alert = t('devise.failure.invalid_otp')
                   end

                   new_user_session_path
                 end

      # 2FA is a one shot deal
      @user&.update!(
        otp_secret:    nil,
        otp_secret_at: nil
      )

      # you get one try at the 2FA code
      session.delete(:otp_user_id)
      session.delete(:otp_method)

      redirect_to location
    end

    private

    def after_sign_in_path_for(_resource)
      if browser.device.mobile?
        # User is logging in on mobile

        if cookies[:push_token].present? && UserPush.where(user_id: current_user.id, target: 'mobile').find_by('data @> ?', { mobile_key: "ExponentPushToken[#{cookies[:push_token]}]" }.to_json).nil?
          # push token was stored in cookies / create UserPush
          UserPush.create(user_id: current_user.id, target: 'mobile', data: { mobile_key: "ExponentPushToken[#{cookies[:push_token]}]" })
          cookies[:push_token] = nil
        end

        session[:previous_url] || central_path
      else
        session[:previous_url] || root_path
      end
    end

    def find_user
      @user = User.find_by(id: session[:otp_user_id])
    end

    def verify_session_otp_user_id!
      redirect_to(new_user_session_path) && return if session[:otp_user_id].nil?
    end
  end
end
