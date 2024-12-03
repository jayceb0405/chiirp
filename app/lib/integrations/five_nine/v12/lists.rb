# frozen_string_literal: true

# app/lib/integrations/five_nine/v12/lists.rb
module Integrations
  module FiveNine
    module V12
      module Lists
        # create a list in Five9
        # Integrations::FiveNine.new(Client).create_list(list_name: String)
        def create_list(args = {})
          @success  = false
          list_name = args.dig(:list_name).to_s

          return if list_name.blank?

          begin
            message  = { 'listName' => list_name }
            result   = five9_client.call(:create_list, message:)

            @success = result.code == 200
          rescue StandardError => e
            # Something else happened
            ProcessError::Report.send(
              error_code:    defined?(e.status) ? e.status : '',
              error_message: "Integrations::FiveNine::V12::Lists.create_list (StandardError): #{e.message}",
              variables:     {
                args:              args.inspect,
                e:                 e.inspect,
                e_methods:         e.public_methods.inspect,
                list_name:         list_name.inspect,
                call_message:      message.inspect,
                result:            result.inspect,
                result_body:       result&.body.inspect,
                result_header:     result&.header.inspect,
                result_http_error: result&.http_error.inspect,
                result_soap_fault: result&.soap_fault.inspect,
                success:           @success.inspect
              },
              file:          __FILE__,
              line:          __LINE__
            )
          end
        end

        # get Lists from Five9
        # five_nine.lists_info
        # lists_info = five_nine.result
        def lists_info
          @success = false
          @result  = []
          @error   = 0
          @message = ''

          begin
            message = { 'listNamePattern' => '.*' }
            call_result = five9_client.call(:get_lists_info, message:)

            @success = true
            @result  = call_result.body.dig(:get_lists_info_response, :return).filter_map { |list| { name: list[:name], size: list[:size] } }
          rescue StandardError => e
            # Something else happened
            @success = false
            @message = e.message

            ProcessError::Report.send(
              error_code:    defined?(e.status) ? e.status : '',
              error_message: "Integrations::FiveNine::V12::Lists.lists_info (StandardError): #{e.message}",
              variables:     {
                call_result:            call_result.inspect,
                call_result_body:       call_result&.body.inspect,
                call_result_header:     call_result&.header.inspect,
                call_result_http_error: call_result&.http_error.inspect,
                call_result_soap_fault: call_result&.soap_fault.inspect,
                e:                      e.inspect,
                e_methods:              e.public_methods.inspect,
                error:                  @error,
                message:                @message,
                call_message:           message.inspect,
                result:                 @result.inspect,
                success:                @success.inspect
              },
              file:          __FILE__,
              line:          __LINE__
            )
          end
        end

        # get Lists names
        # five_nine.lists_names
        # dispositions = five_nine.result.sort_by { |disposition| disposition[:name] }
        def lists_names
          @success = false
          @result  = []
          @error   = 0
          @message = ''

          self.lists_info

          if @success
            @success = true
            @result  = @result.pluck(:name)
          else
            @success = false
            @result  = []
          end
        end

        # remove a Contact from a Five9 List
        # Integrations::FiveNine.new(Client).remove_contact_from_list(contact: Contact, list_name: String)
        #
        # contact = Contact.find(contact_id)
        # contact_hash = contact.attributes.deep_symbolize_keys
        # contact_hash[:contact_phones] = contact.phone_numbers(3)
        # Integrations::FiveNine.new(contact.client).remove_contact_from_list(contact: contact_hash, list_name: 'Test List')
        def remove_contact_from_list(args = {})
          contact   = args.dig(:contact)
          list_name = args.dig(:list_name).to_s

          return unless contact.is_a?(Hash) && list_name.present?

          contact.dig(:contact_phones).compact_blank.each do |contact_phone|
            begin
              message = {
                listName:           list_name,
                listDeleteSettings: {
                  fieldsMapping:  [
                    { columnNumber: 1, fieldName: 'number1', key: true }
                  ],
                  listDeleteMode: 'DELETE_ALL'
                },
                record:             {
                  fields: contact_phone
                }
              }

              result = five9_client.call(:delete_record_from_list, message:)
            rescue Excon::Error::Socket => e
              if e.message.downcase.include?('operation timed out')
                self.delay(
                  run_at:     30.seconds.from_now,
                  priority:   DelayedJob.job_priority('remove_contact_from_five9_list'),
                  queue:      DelayedJob.job_queue('remove_contact_from_five9_list'),
                  contact_id: contact.dig(:id).to_i,
                  process:    'remove_contact_from_five9_list',
                  data:       { contact_id: contact.dig(:id).to_i, list_name: }
                ).remove_contact_from_list(contact:, list_name:)
              else
                ProcessError::Report.send(
                  error_code:    defined?(e.status) ? e.status : '',
                  error_message: "Integrations::FiveNine::V12::Lists.remove_contact_from_list (Excon::Error::Socket): #{e.message}",
                  variables:     {
                    contact:           contact.inspect,
                    e:                 e.inspect,
                    e_methods:         e.public_methods.inspect,
                    list_name:         list_name.inspect,
                    call_message:      message.inspect,
                    result:            result.inspect,
                    result_body:       result&.body.inspect,
                    result_header:     result&.header.inspect,
                    result_http_error: result&.http_error.inspect,
                    result_soap_fault: result&.soap_fault.inspect
                  },
                  file:          __FILE__,
                  line:          __LINE__
                )
              end
            rescue Excon::Error::Timeout => e
              if e.message.downcase.include?('connect_write timeout reached')
                self.delay(
                  run_at:     30.seconds.from_now,
                  priority:   DelayedJob.job_priority('remove_contact_from_five9_list'),
                  queue:      DelayedJob.job_queue('remove_contact_from_five9_list'),
                  contact_id: contact.dig(:id).to_i,
                  process:    'remove_contact_from_five9_list',
                  data:       { contact_id: contact.dig(:id).to_i, list_name: }
                ).remove_contact_from_list(contact:, list_name:)
              else
                ProcessError::Report.send(
                  error_code:    defined?(e.status) ? e.status : '',
                  error_message: "Integrations::FiveNine::V12::Lists.remove_contact_from_list (Excon::Error::Timeout): #{e.message}",
                  variables:     {
                    contact:           contact.inspect,
                    e:                 e.inspect,
                    e_methods:         e.public_methods.inspect,
                    list_name:         list_name.inspect,
                    call_message:      message.inspect,
                    result:            result.inspect,
                    result_body:       result&.body.inspect,
                    result_header:     result&.header.inspect,
                    result_http_error: result&.http_error.inspect,
                    result_soap_fault: result&.soap_fault.inspect
                  },
                  file:          __FILE__,
                  line:          __LINE__
                )
              end
            rescue StandardError => e
              # Something else happened
              ProcessError::Report.send(
                error_code:    defined?(e.status) ? e.status : '',
                error_message: "Integrations::FiveNine::V12::Lists.remove_contact_from_list (StandardError): #{e.message}",
                variables:     {
                  contact:           contact.inspect,
                  e:                 e.inspect,
                  e_methods:         e.public_methods.inspect,
                  list_name:         list_name.inspect,
                  call_message:      message.inspect,
                  result:            result.inspect,
                  result_body:       result&.body.inspect,
                  result_header:     result&.header.inspect,
                  result_http_error: result&.http_error.inspect,
                  result_soap_fault: result&.soap_fault.inspect
                },
                file:          __FILE__,
                line:          __LINE__
              )
            end
          end
        end
      end
    end
  end
end
