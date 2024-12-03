# frozen_string_literal: true

# app/controllers/integrations/dope/v1/automations_controller.rb
module Integrations
  module Dope
    module V1
      module Samples
        # support for configuring automation actions used to send API calls to Dope Marketing
        class EndpointController < Dope::V1::IntegrationsController
          def integrations_sample
            [{ id:          '62e84044bc3c525e0607d4b7',
               name:        'Just Sold',
               description: '',
               type:        'simple',
               mailPieces:  1,
               thumbnail:   'https://production-dope360-public.s3.amazonaws.com/automationImages/front_8878cb30fa4f62aad25bed9b6f9f79e4_mini.jpg',
               status:      'draft',
               createdAt:   '2022-08-01T21:06:12.130Z' },
             { id:          '62e83078bc3c52e5ad07c6d4',
               name:        'Damaged Roof',
               description: '',
               type:        'simple',
               mailPieces:  1,
               thumbnail:   'https://production-dope360-public.s3.amazonaws.com/automationImages/front_7f97ec9c2e3adc89d290c3aedeb3e80d_mini.jpg',
               status:      'draft',
               createdAt:   '2022-08-01T19:58:48.085Z' }]
          end
        end
      end
    end
  end
end
