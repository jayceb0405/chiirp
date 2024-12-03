# frozen_string_literal: true

require 'rails_helper'

# foreman run bundle exec rspec spec/jobs/integrations/servicetitan/v2/events/process_actions_for_event_job_spec.rb
RSpec.describe Integrations::Servicetitan::V2::Events::ProcessActionsForEventJob, type: :job do
  describe '#campaign_name_matches?' do
    let(:job) { described_class.new }

    context 'when action type is not call_completed' do
      it 'returns true' do
        action = { action_type: 'estimate', campaign_name: 'Test Campaign' }
        expect(job.send(:campaign_name_matches?, action, 'Test Campaign')).to be true
      end
    end

    context 'when campaign_name is blank' do
      it 'returns true' do
        action = { action_type: 'call_completed', campaign_name: { segment: '' } }
        expect(job.send(:campaign_name_matches?, action, 'Test Campaign')).to be true
      end
    end

    context 'when campaign_name starts with the given name' do
      it 'returns true' do
        action = { action_type: 'call_completed', campaign_name: { segment: 'Test', start: true } }
        expect(job.send(:campaign_name_matches?, action, 'Test Campaign')).to be true
      end
    end

    context 'when campaign_name does not start with the given name' do
      it 'returns false' do
        action = { action_type: 'call_completed', campaign_name: { segment: 'Test', start: true } }
        expect(job.send(:campaign_name_matches?, action, 'Different')).to be false
      end
    end

    context 'when campaign_name ends with the given name' do
      it 'returns true' do
        action = { action_type: 'call_completed', campaign_name: { end: true, segment: 'paign' } }
        expect(job.send(:campaign_name_matches?, action, 'Test Campaign')).to be true
      end
    end

    context 'when campaign_name does not end with the given name' do
      it 'returns false' do
        action = { action_type: 'call_completed', campaign_name: { end: true, segment: 'paign' } }
        expect(job.send(:campaign_name_matches?, action, 'Different')).to be false
      end
    end

    context 'when campaign_name contains the given name' do
      it 'returns true' do
        action = { action_type: 'call_completed', campaign_name: { contains: true, segment: 'Camp' } }
        expect(job.send(:campaign_name_matches?, action, 'Test Campaign')).to be true
      end
    end

    context 'when campaign_name does not contain the given name' do
      it 'returns false' do
        action = { action_type: 'call_completed', campaign_name: { contains: true, segment: 'Camp' } }
        expect(job.send(:campaign_name_matches?, action, 'Different')).to be false
      end
    end
  end
end
