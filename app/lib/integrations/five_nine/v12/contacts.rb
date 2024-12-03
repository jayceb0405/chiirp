# frozen_string_literal: true

# app/lib/integrations/five_nine/v12/contacts.rb
module Integrations
  module FiveNine
    module V12
      module Contacts
        # add a Contact to a Five9 List
        # Integrations::FiveNine.new(Client).add_contact_to_list(contact: Contact, list_name: String)
        # contact[:contact_phones] is expected to be an array with 3 elements
        def add_contact_to_list(args = {})
          contact    = args.dig(:contact)
          list_name  = args.dig(:list_name).to_s

          return unless contact.is_a?(Hash) && list_name.present?
          return if contact.dig(:contact_phones).compact_blank.blank?

          begin
            message = {
              listName:                 list_name,
              listUpdateSimpleSettings: {
                fieldsMapping: [
                  { columnNumber: 1,  fieldName: 'last_name', key: false },
                  { columnNumber: 2,  fieldName: 'first_name', key: false },
                  { columnNumber: 3,  fieldName: 'street', key: false },
                  { columnNumber: 4,  fieldName: 'city', key: false },
                  { columnNumber: 5,  fieldName: 'state', key: false },
                  { columnNumber: 6,  fieldName: 'zip', key: false },
                  { columnNumber: 7,  fieldName: 'email', key: false },
                  { columnNumber: 8,  fieldName: 'Lead Source', key: false },
                  { columnNumber: 9,  fieldName: 'BusinessUnit', key: false },
                  { columnNumber: 10, fieldName: 'number1', key: true },
                  { columnNumber: 11, fieldName: 'number2', key: false },
                  { columnNumber: 12, fieldName: 'number3', key: false }
                ],
                updateCRM:     true
              },
              record:                   {
                fields: [
                  contact.dig(:lastname).to_s,
                  contact.dig(:firstname).to_s,
                  [contact.dig(:address1).to_s, contact.dig(:address2).to_s].join(','),
                  contact.dig(:city).to_s,
                  contact.dig(:state).to_s,
                  contact.dig(:zipcode).to_s,
                  EmailAddress.valid?(contact.dig(:email).to_s) ? EmailAddress.normal(contact.dig(:email).to_s) : '',
                  contact.dig(:lead_source).to_s,
                  contact.dig(:business_unit).to_s,
                  contact.dig(:contact_phones)[0].to_s,
                  contact.dig(:contact_phones)[1].to_s,
                  contact.dig(:contact_phones)[2].to_s
                ]
              }
            }

            @result = five9_client.call(:add_record_to_list_simple, message:)
          rescue Excon::Error::Socket => e
            if e.message.downcase.include?('operation timed out')
              self.delay(
                run_at:     30.seconds.from_now,
                priority:   DelayedJob.job_priority('add_contact_to_five9_list'),
                queue:      DelayedJob.job_queue('add_contact_to_five9_list'),
                contact_id: contact.dig(:id).to_i,
                process:    'add_contact_to_five9_list',
                data:       { contact:, list_name: }
              ).add_contact_to_list(contact:, list_name:)
            else
              ProcessError::Report.send(
                error_code:    defined?(e.status) ? e.status : '',
                error_message: "Integrations::FiveNine::V12::Contacts.add_contact_to_list (Excon::Error::Socket): #{e.message}",
                variables:     {
                  contact:        contact.inspect,
                  e:              e.inspect,
                  e_full_message: e.full_message.inspect,
                  e_methods:      e.public_methods.inspect,
                  list_name:      list_name.inspect,
                  call_message:   message.inspect
                  # result:            @result.inspect,
                  # result_body:       @result&.body.inspect,
                  # result_header:     @result&.header.inspect,
                  # result_http_error: @result&.http_error.inspect,
                  # result_soap_fault: @result&.soap_fault.inspect
                },
                file:          __FILE__,
                line:          __LINE__
              )
            end
          rescue Savon::SOAPFault => e
            # if @result&.status.to_i == 429
            # ignore "Value of field 'email' has incorrect format"
            # Rails.logger.info "FiveNine::AddContactToList::Savon::SOAPFault: #{e.message}: Contact ID: #{contact.id} File: #{__FILE__} - Line: #{__LINE__}"
            # else
            ProcessError::Report.send(
              error_code:    defined?(e.status) ? e.status : '',
              error_message: "Integrations::FiveNine::V12::Contacts.add_contact_to_list (Savon::SOAPFault): #{e.message}",
              variables:     {
                contact:        contact.inspect,
                e:              e.inspect,
                e_cause:        e.cause.inspect,
                e_exception:    e.exception.inspect,
                e_full_message: e.full_message.inspect,
                e_http:         e.http.inspect,
                e_methods:      e.public_methods.inspect,
                list_name:      list_name.inspect,
                call_message:   message.inspect,
                result:         @result.inspect
                # result_body:       @result&.body.inspect,
                # result_header:     @result&.header.inspect,
                # result_http_error: @result&.http_error.inspect,
                # result_soap_fault: @result&.soap_fault.inspect
              },
              file:          __FILE__,
              line:          __LINE__
            )
            # end
          rescue StandardError => e
            ProcessError::Report.send(
              error_code:    defined?(e.status) ? e.status : '',
              error_message: "Integrations::FiveNine::V12::Contacts.add_contact_to_list (StandardError): #{e.message}",
              variables:     {
                contact:        contact.inspect,
                e:              e.inspect,
                e_full_message: e.full_message.inspect,
                e_methods:      e.public_methods.inspect,
                list_name:      list_name.inspect,
                call_message:   message.inspect,
                result:         @result.inspect
                # result_body:       @result&.body.inspect,
                # result_header:     @result&.header.inspect,
                # result_http_error: @result&.http_error.inspect,
                # result_soap_fault: @result&.soap_fault.inspect
              },
              file:          __FILE__,
              line:          __LINE__
            )
          end
        end

        # attach received images to Contact
        # return an array of ContactAttachment ids
        # Integrations::FiveNine.new(Client).attach_media_to_contact(contact: Contact, media_array: Array)
        def attach_media_to_contact(args = {})
          contact        = args.dig(:contact)
          media_array    = args.dig(:media_array)
          image_id_array = []

          return image_id_array unless contact.is_a?(Contact) && media_array.is_a?(Array) && media_array.present?

          media_array.each do |m|
            begin
              image_id_array << contact.contact_attachments.create!(remote_image_url: m).id
            rescue Cloudinary::CarrierWave::UploadError => e
              ProcessError::Report.send(
                error_message: "Integrations::FiveNine::V12::Contacts.attach_media_to_contact (Cloudinary::CarrierWave::UploadError): #{e.message}",
                variables:     {
                  e:           e.inspect,
                  e_message:   e.message,
                  media:       m,
                  media_array: media_array.inspect,
                  message:     message.inspect
                },
                file:          __FILE__,
                line:          __LINE__
              )
            rescue ActiveRecord::RecordInvalid => e
              ProcessError::Report.send(
                error_message: "Integrations::FiveNine::V12::Contacts.attach_media_to_contact (ActiveRecord::RecordInvalid): #{e.message}",
                variables:     {
                  e:           e.inspect,
                  e_message:   e.message,
                  media:       m,
                  media_array: media_array.inspect,
                  message:     message.inspect
                },
                file:          __FILE__,
                line:          __LINE__
              )
            rescue StandardError => e
              ProcessError::Report.send(
                error_message: "Integrations::FiveNine::V12::Contacts.attach_media_to_contact (StandardError): #{e.message}",
                variables:     {
                  e:           e.inspect,
                  e_message:   e.message,
                  media:       m,
                  media_array: media_array.inspect,
                  message:     message.inspect
                },
                file:          __FILE__,
                line:          __LINE__
              )
            end
          end

          image_id_array
        end
      end
    end
  end
end
