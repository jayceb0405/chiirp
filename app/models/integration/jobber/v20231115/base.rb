# frozen_string_literal: true

# app/models/integration/jobber/v20231115/base.rb
module Integration
  module Jobber
    module V20231115
      class Base < Integration::Jobber::Base
        include Integration::Jobber::V20231115::ImportContacts
        include Integration::Jobber::V20231115::ReferencesDestroyed

        EVENTS = [
          { name: 'Client created', event: 'client_create', description: 'Client created' },
          { name: 'Client updated', event: 'client_update', description: 'Client updated' },
          { name: 'Client deleted', event: 'client_destroy', description: 'Client deleted' },
          { name: 'Request created', event: 'request_create', description: 'Request created' },
          { name: 'Request updated', event: 'request_update', description: 'Request updated' },
          { name: 'Request deleted', event: 'request_delete', description: 'Request deleted' },
          { name: 'Quote created', event: 'quote_create', description: 'Quote created' },
          { name: 'Quote updated', event: 'quote_update', description: 'Quote updated' },
          { name: 'Quote deleted', event: 'quote_destroy', description: 'Quote deleted' },
          { name: 'Job created', event: 'job_create', description: 'Job created' },
          { name: 'Job updated', event: 'job_update', description: 'Job updated' },
          { name: 'Job deleted', event: 'job_destroy', description: 'Job deleted' },
          { name: 'Invoice created', event: 'invoice_create', description: 'Invoice created' },
          { name: 'Invoice updated', event: 'invoice_update', description: 'Invoice updated' },
          { name: 'Invoice deleted', event: 'invoice_delete', description: 'Invoice deleted' },
          { name: 'Visit created', event: 'visit_create', description: 'Visit created' },
          { name: 'Visit updated', event: 'visit_update', description: 'Visit updated' },
          { name: 'Visit completed', event: 'visit_complete', description: 'Visit completed' },
          { name: 'Visit deleted', event: 'visit_destroy', description: 'Visit deleted' }
        ].freeze
        IMPORT_BLOCK_COUNT = 50
        INVOICE_STATUSES = [
          %w[Draft draft],
          ['Awaiting Payment', 'awaiting_payment'],
          %w[Paid paid],
          ['Past Due', 'past_due'],
          ['Bad Debt', 'bad_debt']
        ].freeze
        JOB_STATUSES = [
          ['Requires Invoicing', 'requires_invoicing'],
          %w[Archived archived],
          %w[Late late],
          %w[Today today],
          %w[Upcoming upcoming],
          ['Action Required', 'action_required'],
          ['On Hold', 'on_hold'],
          %w[Unscheduled unscheduled],
          %w[Active active]
        ].freeze
        QUOTE_STATUSES = [
          %w[Draft draft],
          ['Awaiting Response', 'awaiting_response'],
          %w[Archived archived],
          %w[Approved approved],
          %w[Converted converted],
          ['Changes Requested', 'changed_requested']
        ].freeze
        REQUEST_STATUSES = [
          %w[New new],
          %w[Completed completed],
          %w[Converted converted],
          %w[Archived archived],
          %w[Upcoming upcoming],
          %w[Overdue overdue],
          %w[Unscheduled unscheduled],
          ['Assessment Completed', 'assessment_completed'],
          %w[Today today]
        ].freeze
        VISIT_STATUSES = [
          %w[Active active],
          %w[Completed completed],
          %w[Incomplete incomplete],
          %w[Late late],
          %w[Today today],
          %w[Unscheduled unscheduled],
          %w[Upcoming upcoming]
        ].freeze

        # client_id = xx
        # client_api_integration = ClientApiIntegration.find_by(client_id: client_id, target: 'jobber', name: ''); jb_model = Integration::Jobber::V20231115::Base.new(client_api_integration); jb_model.valid_credentials?; jb_client = Integrations::JobBer::V20231115::Base.new(client_api_integration.credentials)

        # return Jobber URL used to create connection
        # jb_model.connect_to_jobber_url
        def connect_to_jobber_url
          @client_api_integration.update(auth_code: RandomCode.new.create(20))
          "https://secure.getjobber.com/api/oauth/authorize?client_id=#{Rails.application.credentials[:jobber][:client_id]}&redirect_uri=#{Rails.application.routes.url_helpers.integrations_jobber_auth_code_url(host: I18n.with_locale(@client_api_integration.client.tenant) { I18n.t("tenant.#{Rails.env}.app_host") })}&state=#{@client_api_integration.auth_code}"
        end

        def create_or_update_client(contact)
          JsonLog.info 'Integration::Jobber::V20231115::Base.create_or_update_client', { contact: }, client_id: @client_api_integration&.client_id, contact_id: contact&.id
          return unless valid_credentials?

          contact_attrs = contact.attributes.symbolize_keys
          contact_attrs[:phone_numbers] = contact.contact_phones.map { |phone| phone.attributes.symbolize_keys }

          if (jobber_client = contact.ext_references.find_by(target: 'jobber'))
            jobber_client_id = @jb_client.client_update(jobber_client.ext_id, contact_attrs)
          else
            jobber_client_id = @jb_client.client_create(contact_attrs)

            @jb_client.property_create(jobber_client_id:, contact: contact_attrs) if jobber_client_id.present?
          end

          return unless jobber_client_id.present? && (contact_ext_reference = contact.ext_references.find_or_create_by(target: 'jobber'))

          contact_ext_reference.update(ext_id: jobber_client_id)
        end

        # delete Jobber credentials
        # jb_model.delete_credentials
        def delete_credentials
          JsonLog.info 'Integration::Jobber::V20231115::Base.delete_credentials', { client_api_integration: @client_api_integration&.attributes_cleaned }, client_id: @client_api_integration&.client_id
          @client_api_integration.credentials['access_token']  = ''
          @client_api_integration.credentials['refresh_token'] = ''
          update_credentials_expiration_and_version
        end

        # disconnect Client from Jobber
        # jb_model.disconnect_account
        def disconnect_account
          JsonLog.info 'Integration::Jobber::V20231115::Base.disconnect_account', { client_api_integration: @client_api_integration&.attributes_cleaned }, client_id: @client_api_integration&.client_id
          valid_credentials?
          jb_client = Integrations::JobBer::V20231115::Base.new(@client_api_integration.credentials)
          jb_client.disconnect_account

          delete_credentials if jb_client.success?

          jb_client.success?
        end

        def tag_applied(args = {})
          return unless args.dig(:contacttag)

          create_or_update_client(args.dig(:contacttag).contact)
        end

        # update ClientApiIntegration.account from Jobber client
        # jb_model.update_account
        def update_account
          JsonLog.info 'Integration::Jobber::V20231115::Base.update_account', { client_api_integration: @client_api_integration&.attributes_cleaned }, client_id: @client_api_integration&.client_id
          valid_credentials?
          @client_api_integration.update(account: Integrations::JobBer::V20231115::Base.new(@client_api_integration.credentials).account)
        end

        # update ClientApiIntegration.credentials from code or refresh_token
        # jb_model.update_credentials(code)
        #   (opt) code: (String)
        def update_credentials(code = nil)
          if code.present?
            update_credentials_by_code(code)
          elsif @client_api_integration.credentials.dig('refresh_token').present?
            update_credentials_by_refresh_token
          end

          @client_api_integration.credentials.dig('access_token').present? && @client_api_integration.credentials.dig('refresh_token').present?
        end

        # update ClientApiIntegration.credentials from code
        # jb_model.update_credentials_by_code(code)
        #   (opt) code: (String)
        def update_credentials_by_code(code)
          @client_api_integration.credentials = Integrations::JobBer::V20231115::Base.new(@client_api_integration.credentials).request_access_token(code)
          update_credentials_expiration_and_version
          @jb_client = Integrations::JobBer::V20231115::Base.new(@client_api_integration.credentials)
        end

        # update ClientApiIntegration.credentials from refresh token
        # jb_model.update_credentials_by_refresh_token
        def update_credentials_by_refresh_token
          @client_api_integration.credentials = Integrations::JobBer::V20231115::Base.new(@client_api_integration.credentials).refresh_access_token(@client_api_integration.credentials['refresh_token'])
          update_credentials_expiration_and_version
          @jb_client = Integrations::JobBer::V20231115::Base.new(@client_api_integration.credentials)
        end

        # update ClientApiIntegration.credentials expires_at & version
        # jb_model.update_credentials_expiration_and_version
        def update_credentials_expiration_and_version
          if @client_api_integration.credentials.dig('access_token').present? && @client_api_integration.credentials.dig('refresh_token').present?
            @client_api_integration.credentials[:expires_at] = 50.minutes.from_now
            @client_api_integration.credentials[:version]    = '20231115'
            @client_api_integration.save
          else
            @client_api_integration.update(credentials: {})
          end
        end

        # validate the access_token & refresh if necessary
        # jb_model.valid_credentials?
        def valid_credentials?
          if @client_api_integration.credentials.present? && Integrations::JobBer::V20231115::Base.new(@client_api_integration.credentials).valid_credentials?
            true
          elsif @client_api_integration.credentials.present?
            update_credentials
          else
            @client_api_integration.update(credentials: {})
            false
          end
        end
      end
    end
  end
end
