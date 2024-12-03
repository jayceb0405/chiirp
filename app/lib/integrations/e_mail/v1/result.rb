# frozen_string_literal: true

# https://docs.sendgrid.com/for-developers/sending-email/automating-subusers
# https://docs.sendgrid.com/api-reference/subusers-api/list-all-subusers
# app/lib/integrations/e_mail/v1/result.rb
# Integrations::EMail::V1::Result.new(error, message, success, result)
module Integrations
  module EMail
    module V1
      class Result
        attr_accessor :error, :message, :success, :result, :faraday_result
        alias success? success

        def initialize(error, message, success, result, faraday_result)
          self.error          = error.to_i
          self.message        = message.to_s
          self.success        = success.to_bool
          self.result         = result
          self.faraday_result = faraday_result
        end
      end
    end
  end
end
