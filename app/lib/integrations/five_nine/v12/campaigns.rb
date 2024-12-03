# frozen_string_literal: true

# app/lib/integrations/five_nine/v12/campaigns.rb
module Integrations
  module FiveNine
    module V12
      module Campaigns
        # get Campaigns from Five9
        # five_nine.campaigns
        # campaigns = five_nine.result.sort
        def campaigns
          @success = false
          @result  = []
          @error   = 0
          @message = ''

          begin
            message     = { 'campaignNamePattern' => '.*' }
            call_result = five9_client.call(:get_campaigns, message:)

            @success = true
            @result  = call_result.body.dig(:get_campaigns_response, :return).pluck(:name)
          rescue Savon::HTTPError => e
            @success = false
            @error   = e.http.code
            @message = e.message

            ProcessError::Report.send(
              error_code:    @error,
              error_message: "Integrations::FiveNine::V12::Campaigns.campaigns (Savon::HTTPError): #{e.message}",
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
            @error   = e.http.code
            @message = e.message

            ProcessError::Report.send(
              error_code:   @error,
              error_essage: "Integrations::FiveNine::V12::Campaigns.campaigns (Savon::InvalidResponseError): #{e.message}",
              variables:    {
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
              file:         __FILE__,
              line:         __LINE__
            )
          rescue StandardError => e
            # Something else happened
            @success = false
            @message = e.message

            ProcessError::Report.send(
              error_code:    defined?(e.status) ? e.status : '',
              error_message: "Integrations::FiveNine::V12::Campaigns.campaigns (StandardError): #{e.message}",
              variables:     {
                call_result:            call_result.inspect,
                call_result_body:       call_result&.body.inspect,
                call_result_header:     call_result&.header.inspect,
                call_result_http_error: call_result&.http_error.inspect,
                call_result_soap_fault: call_result&.soap_fault.inspect,
                e:                      e.inspect,
                e_methods:              e.public_methods.inspect,
                error:                  @error.inspect,
                message:                @message.inspect,
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
