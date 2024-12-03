# frozen_string_literal: true

# app/models/Integration/vitally/v2024/base.rb
module Integration
  module Vitally
    module V2024
      class Base
        attr_reader :error, :message, :result, :success
        alias success? success

        include Vitally::V2024::Accounts
        include Vitally::V2024::Notes
        include Vitally::V2024::Users

        # vt_model = Integration::Vitally::V2024::Base.new
        def initialize
          reset_attributes
          @vt_client = Integrations::VitalLy::V2024::Base.new
        end

        private

        def reset_attributes
          @error   = 0
          @message = ''
          @result  = nil
          @success = false
        end

        def update_attributes_from_client
          @error   = @vt_client.error
          @message = @vt_client.message
          @result  = @vt_client.result
          @success = @vt_client.success?
        end
      end
    end
  end
end
