# frozen_string_literal: true

# app/models/Integration/searchlight/v1/base.rb
module Integration
  module Searchlight
    module V1
      class Base
        # set up for Client id 3030 first

        # sl_model = Integration::Searchlight::V1::Base.new(client)
        #   (req) client: (Client)
        def initialize(client = nil)
          self.client = client
        end

        # POST Messages::Message to SearchLight
        # sl_model.post_message()
        #   (req) message:   (Messages::Message)
        #   (req) action_at: (DateTime)
        def post_message(message, action_at)
          return false unless message.is_a?(Messages::Message) && action_at.respond_to?(:iso8601) && self.validate_required_params && message.contact.contact_phones.length < 25

          @sl_client.post_action(
            action:              'message',
            action_at:           action_at.iso8601,
            automated:           message.automated,
            campaign_id:         Triggeraction.find_by(id: message.triggeraction_id)&.trigger&.campaign_id,
            campaign_name:       Triggeraction.find_by(id: message.triggeraction_id)&.trigger&.campaign&.name,
            contact_email:       message.contact.email,
            contact_ext_id:      message.contact.ext_references.find_by(target: self.ext_client_api_integration&.target.to_s.sub('housecall', 'housecallpro'))&.ext_id,
            contact_id:          message.contact.id,
            contact_name:        message.contact.fullname,
            contact_phones:      message.contact.contact_phones.map(&:phone),
            created_at:          message.created_at.iso8601,
            from_phone:          message.from_phone,
            message:             message.message,
            message_id:          message.id,
            message_status:      message.status,
            quickpage_id:        0,
            quickpage_name:      '',
            revenue_attr:        self.revenue_gen?(Triggeraction.find_by(id: message.triggeraction_id)&.trigger&.campaign_id),
            sitechat_id:         0,
            sitechat_name:       '',
            survey_id:           0,
            survey_name:         '',
            survey_screen_id:    0,
            survey_screen_name:  '',
            survey_result_id:    0,
            survey_result_data:  '',
            to_phone:            message.to_phone,
            type:                message.msg_type,
            voice_recording_url: message.voice_recording&.url
          )

          @sl_client.success?
        end

        # POST Surveys::Survey to SearchLight
        # sl_model.post_survey()
        #   (req) action_at:        (DateTime)
        #   (opt) contact_id:       (Integer)
        #   (req) survey_id:        (Integer)
        #   (opt) survey_result_id: (Integer)
        #   (req) survey_screen_id: (Integer)
        def post_survey(contact_id, survey_id, survey_screen_id, survey_result_id, action_at)
          return false unless (survey = @client.surveys.find_by(id: survey_id)) && (survey_screen = survey.screens.find_by(id: survey_screen_id)) &&
                              action_at.respond_to?(:iso8601) && self.validate_required_params

          contact = @client.contacts.find_by(id: contact_id)

          return false unless contact&.contact_phones&.length.to_i < 25

          survey_result = survey.results.find_by(id: survey_result_id)

          @sl_client.post_action(
            action:              'survey',
            action_at:           action_at.iso8601,
            automated:           false,
            campaign_id:         0,
            campaign_name:       '',
            contact_email:       contact&.email,
            contact_ext_id:      contact&.ext_references&.find_by(target: self.ext_client_api_integration&.target.to_s.sub('housecall', 'housecallpro'))&.ext_id,
            contact_id:          contact&.id,
            contact_name:        contact&.fullname,
            contact_phones:      contact&.contact_phones&.map(&:phone),
            created_at:          contact&.created_at&.iso8601,
            from_phone:          '',
            message:             '',
            message_id:          0,
            message_status:      '',
            quickpage_id:        0,
            quickpage_name:      '',
            revenue_attr:        false,
            sitechat_id:         0,
            sitechat_name:       '',
            survey_id:           survey.id,
            survey_name:         survey.name,
            survey_screen_id:    survey_screen.id,
            survey_screen_name:  survey_screen.name,
            survey_result_id:    survey_result&.id,
            survey_result_data:  survey_result&.data,
            to_phone:            '',
            type:                '',
            voice_recording_url: ''
          )

          @sl_client.success?
        end

        # POST UserContactForm to SearchLight
        # sl_model.post_user_contact_form()
        #   (req) contact_id:           (Contact)
        #   (req) user_contact_form_id: (UserContactForm)
        #   (req) action_at:            (DateTime)
        def post_user_contact_form(contact_id, user_contact_form_id, action_at)
          return false unless (contact = @client.contacts.find_by(id: contact_id)) && (user_contact_form = @client.user_contact_forms.find_by(id: user_contact_form_id)) &&
                              action_at.respond_to?(:iso8601) && self.validate_required_params && contact.contact_phones.length < 25

          @sl_client.post_action(
            action:              'quickpage',
            action_at:           action_at.iso8601,
            automated:           false,
            campaign_id:         0,
            campaign_name:       '',
            contact_email:       contact.email,
            contact_ext_id:      contact.ext_references.find_by(target: self.ext_client_api_integration&.target.to_s.sub('housecall', 'housecallpro'))&.ext_id,
            contact_id:          contact.id,
            contact_name:        contact.fullname,
            contact_phones:      contact.contact_phones.map(&:phone),
            created_at:          contact.created_at.iso8601,
            from_phone:          '',
            message:             '',
            message_id:          0,
            message_status:      '',
            quickpage_id:        user_contact_form.id,
            quickpage_name:      user_contact_form.form_name,
            revenue_attr:        false,
            sitechat_id:         0,
            sitechat_name:       '',
            survey_id:           0,
            survey_name:         '',
            survey_screen_id:    0,
            survey_screen_name:  '',
            survey_result_id:    0,
            survey_result_data:  '',
            to_phone:            '',
            type:                '',
            voice_recording_url: ''
          )

          @sl_client.success?
        end

        # POST Clients::Widget to SearchLight
        # sl_model.post_widget()
        #   (req) action_at:        (DateTime)
        #   (req) client_widget_id: (Clients::Widget)
        #   (req) contact_id:       (Contact)
        def post_widget(contact_id, client_widget_id, action_at)
          return false unless (contact = @client.contacts.find_by(id: contact_id)) && (client_widget = @client.client_widgets.find_by(id: client_widget_id)) &&
                              action_at.respond_to?(:iso8601) && self.validate_required_params && contact.contact_phones.length < 25

          @sl_client.post_action(
            action:              'sitechat',
            action_at:           action_at.iso8601,
            automated:           false,
            campaign_id:         0,
            campaign_name:       '',
            contact_email:       contact.email,
            contact_ext_id:      contact.ext_references.find_by(target: self.ext_client_api_integration&.target.to_s.sub('housecall', 'housecallpro'))&.ext_id,
            contact_id:          contact.id,
            contact_name:        contact.fullname,
            contact_phones:      contact.contact_phones.map(&:phone),
            created_at:          contact.created_at.iso8601,
            from_phone:          '',
            message:             '',
            message_id:          0,
            message_status:      '',
            quickpage_id:        0,
            quickpage_name:      '',
            revenue_attr:        false,
            sitechat_id:         client_widget.id,
            sitechat_name:       client_widget.widget_name,
            survey_id:           0,
            survey_name:         '',
            survey_screen_id:    0,
            survey_screen_name:  '',
            survey_result_id:    0,
            survey_result_data:  '',
            to_phone:            '',
            type:                '',
            voice_recording_url: ''
          )

          @sl_client.success?
        end

        def update_searchlight_key
          return false unless self.validate_required_params && (searchlight_key = @sl_client.request_key).present?

          @client_api_integration.update(api_key: searchlight_key)

          true
        end

        private

        def client=(client)
          @client = case client
                    when Client
                      client
                    when Integer
                      Client.find_by(id: client)
                    else
                      Client.new
                    end

          return if @client.integrations_allowed.exclude?('searchlight')

          @client_api_integration = @client.client_api_integrations.find_by(target: 'searchlight', name: '')

          @sl_client = Integrations::SearchLight::V1::Base.new(
            client_id:          @client.id,
            client_name:        @client.name,
            client_ext_id:      self.client_ext_id.to_s,
            client_integration: self.ext_client_api_integration&.target.to_s.sub('housecall', 'housecallpro')
          )
        end

        def client_ext_id
          case self.ext_client_api_integration&.target
          when 'servicetitan'
            self.ext_client_api_integration&.credentials&.dig('tenant_id')
          when 'housecall'
            self.ext_client_api_integration&.company&.dig('id')
          end
        end

        def ext_client_api_integration
          return @ext_client_api_integration if @ext_client_api_integration.present?

          if ((@ext_client_api_integration = @client.client_api_integrations.find_by(target: 'servicetitan', name: '')) && @ext_client_api_integration&.credentials&.dig('tenant_id').present?) ||
             ((@ext_client_api_integration = @client.client_api_integrations.find_by(target: 'housecall', name: '')) && @ext_client_api_integration&.company&.dig('id').present?)
            @ext_client_api_integration
          else
            @ext_client_api_integration = nil
          end
        end

        def revenue_gen?(campaign_id)
          @client_api_integration.revenue_gen&.dig('campaign_ids')&.include?(campaign_id)&.to_bool
        end

        def validate_required_params
          @client.is_a?(Client) && self.ext_client_api_integration.is_a?(ClientApiIntegration) && @client_api_integration.is_a?(ClientApiIntegration) && @client_api_integration.active
        end
      end
    end
  end
end
