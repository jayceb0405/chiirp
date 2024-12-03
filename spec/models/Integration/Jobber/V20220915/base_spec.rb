# frozen_string_literal: true

# spec/models/integration/jobber/v20220915/base_spec.rb.rb
# foreman run bundle exec rspec spec/models/integration/jobber/v20220915/base_spec.rb
require 'rails_helper'

RSpec.describe Integration::Jobber::V20220915::Base do
  let(:integration) { create :client_api_integration_for_jobber }
  let(:jb_model) { Integration::Jobber::V20220915::Base.new(integration) }

  describe 'update_account' do
    it 'should not delete record data' do
      jb_model.update_account
      expect(integration.reload.data.dig('credentials', 'version')).not_to be_blank
    end
  end
end
