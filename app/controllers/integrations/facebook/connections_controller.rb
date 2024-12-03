# frozen_string_literal: true

# app/controllers/integrations/facebook/connections_controller.rb
module Integrations
  module Facebook
    class ConnectionsController < Facebook::IntegrationsController
      # (DELETE) revoke a User's Permissions
      # /integrations/facebook/connections
      # integrations_facebook_connections_path
      # integrations_facebook_connections_url
      def destroy
        user = @user_api_integration.users.find { |u| u['id'] == params.permit(:user_id).dig(:user_id).to_s }

        if user.present? && Integrations::FaceBook::Base.new(fb_user_id: user.dig('id'), token: user.dig('token')).user_delete

          @user_api_integration.pages.find_all { |p| p['user_id'] == user['id'] }.each do |page|
            if (user_api_integration_fb_leads = @user_api_integration.user.user_api_integrations.find_by(target: 'facebook', name: 'leads'))
              user_api_integration_fb_leads.destroy
            end

            if (user_api_integration_fb_messenger = @user_api_integration.user.user_api_integrations.find_by(target: 'facebook', name: 'messenger'))
              user_api_integration_fb_messenger.destroy
            end

            @user_api_integration.pages.delete(page)
          end

          @user_api_integration.users.delete(user)
          @user_api_integration.save
        end

        respond_to do |format|
          format.js { render partial: 'integrations/facebook/js/show', locals: { cards: %w[edit_connections] } }
          format.html { redirect_to integrations_facebook_integration_path }
        end
      end

      # (GET) Facebook integration configuration screen
      # /integrations/facebook/connections/edit
      # edit_integrations_facebook_connections_path
      # edit_integrations_facebook_connections_url
      def edit
        respond_to do |format|
          format.js { render partial: 'integrations/facebook/js/show', locals: { cards: %w[edit_connections] } }
          format.html { redirect_to integrations_facebook_integration_path }
        end
      end

      # (PATCH/PUT) subscribe/unsubscribe to Facebook Leads/Messenger for a page
      # /integrations/facebook/connections
      # integrations_facebook_connections_path
      # integrations_facebook_connections_url
      def update
        @fb_page_id = params.permit(:fb_page_id).dig(:fb_page_id).to_s
        permission  = params.permit(:permission).dig(:permission).to_s
        subscribe   = params.permit(:subscribe).dig(:subscribe).to_bool
        fb_model    = Integration::Facebook::Base.new(@user_api_integration)

        if @fb_page_id.present? && (fb_page = @user_api_integration.pages.find { |p| p['id'] == @fb_page_id })

          case permission
          when 'leads'

            if subscribe
              permissions = if fb_model.page_subscribed?(page_id: fb_page['id'], permissions: Integration::Facebook::Base::PAGE_PERMISSIONS_MESSENGER)
                              Integration::Facebook::Base::PAGE_PERMISSIONS_LEADS + Integration::Facebook::Base::PAGE_PERMISSIONS_MESSENGER
                            else
                              Integration::Facebook::Base::PAGE_PERMISSIONS_LEADS
                            end

              fb_model.page_subscribe(page_id: @fb_page_id, permissions:)
            elsif fb_model.page_subscribed?(page_id: @fb_page_id, permissions: Integration::Facebook::Base::PAGE_PERMISSIONS_MESSENGER)
              fb_model.page_subscribe(page_id: fb_page['id'], permissions: Integration::Facebook::Base::PAGE_PERMISSIONS_MESSENGER)
            else
              fb_model.page_unsubscribe(page_id: fb_page['id'])
            end
          when 'messenger'

            if subscribe
              permissions = if fb_model.page_subscribed?(page_id: fb_page['id'], permissions: Integration::Facebook::Base::PAGE_PERMISSIONS_LEADS)
                              Integration::Facebook::Base::PAGE_PERMISSIONS_LEADS + Integration::Facebook::Base::PAGE_PERMISSIONS_MESSENGER
                            else
                              Integration::Facebook::Base::PAGE_PERMISSIONS_MESSENGER
                            end

              fb_model.page_subscribe(page_id: fb_page['id'], permissions:)
            elsif fb_model.page_subscribed?(page_id: fb_page['id'], permissions: Integration::Facebook::Base::PAGE_PERMISSIONS_LEADS)
              fb_model.page_subscribe(page_id: fb_page['id'], permissions: Integration::Facebook::Base::PAGE_PERMISSIONS_LEADS)
            else
              fb_model.page_unsubscribe(page_id: fb_page['id'])
            end
          end
        end
      end
    end
  end
end
