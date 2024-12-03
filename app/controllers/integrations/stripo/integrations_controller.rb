# frozen_string_literal: true

# app/controllers/integrations/servicetitan/integrations_controller.rb
module Integrations
  module Stripo
    class IntegrationsController < ApplicationController
      before_action :authorize_user!, except: %i[html_css]
      before_action :email_template, only: %i[html_css]

      # (GET) return html & css for a specific EmailTemplate
      # /integrations/stripo/html_css/:id
      # integrations_stripo_html_css_path(:id)
      # integrations_stripo_html_css_url(:id)
      def html_css
        render json: [@email_template.html, @email_template.css], status: :ok
      end

      private

      def authorize_user!
        return if current_user.team_member?

        raise ExceptionHandlers::UserNotAuthorized.new('Stripo Test', root_path)
      end

      def email_template
        if defined?(current_user) && params.include?(:id)
          @email_template = current_user.client.email_templates.find_by(id: params[:id].to_i) || EmailTemplate.find_by(client_id: nil, id: params[:id].to_i)

          sweetalert_error('Unknown Email Template!', 'The Email Template you requested could not be found.', '', { persistent: 'OK' }) unless @email_template
        else
          sweetalert_error('Unknown Email Template!', 'A Email Template was NOT requested.', '', { persistent: 'OK' })
        end

        return if @email_template

        respond_to do |format|
          format.js { render js: "window.location = '#{root_path}'" and return false }
          format.html { redirect_to root_path and return false }
        end
      end
    end
  end
end
