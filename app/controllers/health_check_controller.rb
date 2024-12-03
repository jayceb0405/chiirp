# frozen_string_literal: true

# app/controllers/health_check_controller.rb
class HealthCheckController < ActionController::Base # rubocop:disable Rails/ApplicationController
  def up
    # render json: { status: 'up', remote_ip: request.remote_ip, http_forwarded_for: request.headers['HTTP_X_FORWARDED_FOR'], cookies: request.session, user: current_user }
    head :ok
  end
end
