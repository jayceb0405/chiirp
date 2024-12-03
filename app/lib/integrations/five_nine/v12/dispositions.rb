# frozen_string_literal: true

# app/lib/integrations/five_nine/v12/dispositions.rb
module Integrations
  module FiveNine
    module V12
      module Dispositions
        # get Five9 dispositions
        # five_nine.dispositions
        # dispositions = five_nine.result.sort_by { |disposition| disposition[:name] }
        def dispositions
          @success = false
          @result  = []
          @error   = 0
          @message = ''

          begin
            message     = { 'dispositionNamePattern' => '.*' }
            call_result = five9_client.call(:get_dispositions, message:)

            @success    = true
            @result     = call_result.body.dig(:get_dispositions_response, :return).map { |disp| { name: disp[:name], description: disp[:description] } }
          rescue Savon::HTTPError => e
            @success = false
            @error   = e.http.code
            @message = e.message

            ProcessError::Report.send(
              error_code:    @error,
              error_message: "Integrations::FiveNine::V12::Dispositions.dispositions (Savon::HTTPError): #{e.message}",
              variables:     {
                call_result:            call_result.inspect,
                call_result_body:       call_result&.body.inspect,
                call_result_header:     call_result&.header.inspect,
                call_result_http_error: call_result&.http_error.inspect,
                call_result_soap_fault: call_result&.soap_fault.inspect,
                e:                      e.inspect,
                e_http:                 e.http.inspect,
                e_http_code:            e.http.code.inspect,
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
          rescue Savon::InvalidResponseError => e
            @success = false
            @error = e.http.code
            @message = e.message

            ProcessError::Report.send(
              error_code:    @error,
              error_message: "Integrations::FiveNine::V12::Dispositions.dispositions (Savon::InvalidResponseError): #{e.message}",
              variables:     {
                call_result:            call_result.inspect,
                call_result_body:       call_result&.body.inspect,
                call_result_header:     call_result&.header.inspect,
                call_result_http_error: call_result&.http_error.inspect,
                call_result_soap_fault: call_result&.soap_fault.inspect,
                e:                      e.inspect,
                e_http:                 e.http.inspect,
                e_http_code:            e.http.code.inspect,
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
          rescue StandardError => e
            @success = false
            # @error    = e.http.code
            @message = e.message

            ProcessError::Report.send(
              error_code:    @error,
              error_message: "Integrations::FiveNine::V12::Dispositions.dispositions (StandardError): #{e.message}",
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
      end
    end
  end
end
