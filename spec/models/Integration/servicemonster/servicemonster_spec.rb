# frozen_string_literal: true

# spec/models/integration/servicemonster/servicemonster_spec.rb
# foreman run bundle exec rspec spec/models/integration/servicemonster/servicemonster_spec.rb
require 'rails_helper'

RSpec.describe Integration::Servicemonster do
  # let(:client_api_integration) { create :client_api_integration_for_servicetitan }

  [
    { order: { type: 'order', voided: false }, criteria: { type: 'order', voided: false }, result: true },
    { order: { type: 'order', voided: false }, criteria: { type: 'order', voided: true }, result: false },
    { order: { type: 'order', voided: true }, criteria: { type: 'order', voided: false }, result: false },
    { order: { type: 'order', voided: true }, criteria: { type: 'order', voided: true }, result: true },
    { order: { type: 'estimate', voided: false }, criteria: { type: 'estimate', voided: false }, result: true },
    { order: { type: 'estimate', voided: false }, criteria: { type: 'estimate', voided: true }, result: false },
    { order: { type: 'estimate', voided: true }, criteria: { type: 'estimate', voided: false }, result: false },
    { order: { type: 'estimate', voided: true }, criteria: { type: 'estimate', voided: true }, result: true },
    { order: { type: 'invoice', voided: false }, criteria: { type: 'invoice', voided: false }, result: true },
    { order: { type: 'invoice', voided: false }, criteria: { type: 'invoice', voided: true }, result: false },
    { order: { type: 'invoice', voided: true }, criteria: { type: 'invoice', voided: false }, result: false },
    { order: { type: 'invoice', voided: true }, criteria: { type: 'invoice', voided: true }, result: true },
    { order: { type: 'estimate', voided: false }, criteria: { type: 'order', voided: false }, result: false },
    { order: { type: 'estimate', voided: false }, criteria: { type: 'order', voided: true }, result: false },
    { order: { type: 'estimate', voided: true }, criteria: { type: 'order', voided: false }, result: false },
    { order: { type: 'estimate', voided: true }, criteria: { type: 'order', voided: true }, result: false },
    { order: { type: 'estimate', voided: false }, criteria: { type: 'invoice', voided: false }, result: false },
    { order: { type: 'estimate', voided: false }, criteria: { type: 'invoice', voided: true }, result: false },
    { order: { type: 'estimate', voided: true }, criteria: { type: 'invoice', voided: false }, result: false },
    { order: { type: 'estimate', voided: true }, criteria: { type: 'invoice', voided: true }, result: false },
    { order: { type: 'voided', voided: false }, criteria: { type: 'order', voided: false }, result: true },
    { order: { type: 'voided', voided: false }, criteria: { type: 'order', voided: true }, result: true },
    { order: { type: 'voided', voided: true }, criteria: { type: 'order', voided: false }, result: true },
    { order: { type: 'voided', voided: true }, criteria: { type: 'order', voided: true }, result: true }
  ].each do |x|
    it "Test Integration::Servicemonster.order_type_matches?(#{x})" do
      expect(Integration::Servicemonster.order_type_matches?(order: x[:order], criteria: x[:criteria])).to eq(x[:result])
    end
  end
end
# order:    {
#   type:   result.dig(:order, :type).to_s.sub('work ', ''),
#   voided: result.dig(:order, :type_voided)
# }
# criteria: {
#   type:   args.dig(:order_type),
#   voided: args.dig(:order_type_voided)
# }
