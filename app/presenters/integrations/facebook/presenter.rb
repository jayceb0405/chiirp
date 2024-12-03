# frozen_string_literal: true

# app/presenters/integrations/facebook/presenter.rb
module Integrations
  module Facebook
    class Presenter
      attr_reader :client, :facebook_form, :user_api_integration, :user_api_integration_leads, :user_api_integration_messenger

      # presenter = local_assigns.dig(:presenter) || Integrations::Facebook::Presenter.new(user_api_integration: @user_api_integration)
      def initialize(args = {})
        self.user_api_integration           = args.dig(:user_api_integration)
        self.user_api_integration_leads     = args.dig(:user_api_integration_leads)
        self.user_api_integration_messenger = args.dig(:user_api_integration_messenger)
      end

      def campaigns_allowed
        self.client.campaigns_count.positive?
      end

      def facebook_form=(form_id)
        @facebook_form = @user_api_integration_leads.forms.map(&:deep_symbolize_keys).find { |f| f[:id] == form_id } || {}
      end

      def facebook_form_defined?
        (@facebook_form.dig(:campaign_id).to_i + @facebook_form.dig(:group_id).to_i + @facebook_form.dig(:tag_id).to_i + @facebook_form.dig(:stage_id).to_i).positive?
      end

      def facebook_form_group
        id = self.facebook_form.dig(:group_id).to_i
        id.positive? ? Group.find_by(client_id: @client.id, id:) : nil
      end

      def facebook_form_tag
        id = self.facebook_form.dig(:tag_id).to_i
        id.positive? ? Tag.find_by(client_id: @client.id, id:) : nil
      end

      def forms_defined_count
        @user_api_integration_leads&.forms&.map(&:deep_symbolize_keys)&.find_all { |f| (f.dig(:campaign_id).to_i + f.dig(:group_id).to_i + f.dig(:tag_id).to_i + f.dig(:stage_id).to_i).positive? }&.count || 0
      end

      def groups_allowed
        self.client.groups_count.positive?
      end

      def options_for_campaign_hash
        Campaign.for_select(@client.id).pluck(:name, :id)
      end

      def options_for_key_hash
        ::Webhook.internal_key_hash(@client, 'contact', %w[personal ext_references]).invert.to_a + [['OK to Text', 'ok2text'], ['OK to Email', 'ok2email']] + ::Webhook.internal_key_hash(@client, 'contact', %w[phones]).merge(@client.client_custom_fields.pluck(:id, :var_name).to_h).invert.to_a
      end

      def page_forms(user_id, page_id)
        if @user_id == user_id && @page_id == page_id && @page_forms.present?
          @page_forms
        else
          @page_id      = page_id
          @user_id      = user_id
          @page_forms ||= @fb_model.page_lead_forms(page_id:).sort_by { |p| p[:name] }
        end
      end

      def stages_allowed
        self.client.stages_count.positive?
      end

      def user_api_integration=(user_api_integration)
        @user_api_integration = case user_api_integration
                                when UserApiIntegration
                                  user_api_integration
                                when Integer
                                  UserApiIntegration.find_by(id: user_api_integration)
                                else
                                  UserApiIntegration.new
                                end

        @client     = @user_api_integration.user.client
        @fb_model   = Integration::Facebook::Base.new(@user_api_integration)
        @page_id    = nil
        @user_id    = nil
      end

      def user_api_integration_leads=(user_api_integration_leads)
        @user_api_integration_leads = case user_api_integration_leads
                                      when UserApiIntegration
                                        user_api_integration_leads
                                      when Integer
                                        UserApiIntegration.find_by(id: user_api_integration_leads)
                                      else
                                        if @user_api_integration && (uai = @user_api_integration.user.user_api_integrations.find_by(target: 'facebook', name: 'leads'))
                                          @user_api_integration_leads = uai
                                        else
                                          UserApiIntegration.new
                                        end
                                      end

        @page_forms = nil
      end

      def user_api_integration_messenger=(user_api_integration_messenger)
        @user_api_integration_messenger = case user_api_integration_messenger
                                          when UserApiIntegration
                                            user_api_integration_messenger
                                          when Integer
                                            UserApiIntegration.find_by(id: user_api_integration_messenger)
                                          else
                                            if @user_api_integration && (uai = @user_api_integration.user.user_api_integrations.find_by(target: 'facebook', name: 'messenger'))
                                              @user_api_integration_messenger = uai
                                            else
                                              UserApiIntegration.new
                                            end
                                          end
      end
    end
  end
end
