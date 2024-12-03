# frozen_string_literal: true

# app/presenters/integrations/sendgrid/v1/presenter.rb
module Integrations
  module Sendgrid
    module V1
      class Presenter < BasePresenter
        def email_addresses
          @client_api_integration.email_addresses.split(',').compact_blank
        end

        def email_addresses_count
          self.email_addresses.length
        end

        def email_addresses_to_s
          self.email_addresses.join(',')
        end
      end
    end
  end
end
