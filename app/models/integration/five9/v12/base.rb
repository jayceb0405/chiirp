# frozen_string_literal: true

# app/models/integration/five9/v12/base.rb
module Integration
  module Five9
    module V12
      class Base < Integration::Five9::Base
        # prepare Contact data hash for Five9
        # Integration::Five9.contact_prep_for_five9(contact_hash)
        def contact_prep_for_five9(contact)
          response = contact.attributes.deep_symbolize_keys
          response[:contact_phones] = contact.phone_numbers(3)
          response[:lead_source]    = ''
          response[:business_unit]  = ''
          response[:lead_source]    = Contacttag.where(contact_id: contact.id, tag_id: @client_api_integration&.lead_sources)&.order(created_at: :desc)&.first&.tag&.name.to_s

          response
        end

        def tag_applied(args = {})
          # a Tag was applied to Contact / if Contact belongs to a Five9 Client do something
          # Integration::Five9.tag_applied(contacttag: Contacttag)
          contacttag = args.dig(:contacttag)

          if contacttag.is_a?(Contacttag) &&
             (list = @client_api_integration.lists.deep_symbolize_keys.find { |_key, value| value[:tag_id] == contacttag.tag_id })
            # Tag applied is a list Tag

            contact_hash = contact_prep_for_five9(contacttag.contact)

            if list[1][:action].to_s == 'add'
              @f9_client.delay(
                priority:   DelayedJob.job_priority('add_contact_to_five9_list'),
                queue:      DelayedJob.job_queue('add_contact_to_five9_list'),
                contact_id: contacttag.contact_id,
                process:    'add_contact_to_five9_list',
                data:       { contact: contact_hash, list_name: list[1][:name] }
              ).call(:add_contact_to_list, { contact: contact_hash, list_name: list[1][:name] })
            else
              @f9_client.delay(
                priority:   DelayedJob.job_priority('remove_contact_from_five9_list'),
                queue:      DelayedJob.job_queue('remove_contact_from_five9_list'),
                contact_id: contacttag.contact_id,
                process:    'remove_contact_from_five9_list',
                data:       { contact: contact_hash, list_name: list[1][:name] }
              ).call(:remove_contact_from_list, { contact: contact_hash, list_name: list[1][:name] })
            end
          end
        end

        def valid_credentials?
          @success = @f9_client.valid_credentials?
          @message = @success ? 'Valid credentials' : 'Invalid credentials'
          @result  = @success
        end
      end
    end
  end
end
