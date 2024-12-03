# frozen_string_literal: true

require 'rails_helper'

# foreman run bundle exec rspec spec/models/contacts/job_spec.rb
RSpec.describe Contacts::Job do
  let(:client_api_integration) { create :client_api_integration_for_cardx }
  let(:client) { client_api_integration.client }
  let(:contact) { create :contact, client: }
  let(:job) { create :job, contact: }

  # rubocop:disable Lint/InterpolationCheck
  describe 'message_tag_replace' do
    it 'replaces job-outstanding_balance' do
      expect(job.message_tag_replace('#{job-outstanding_balance}')).to eq('$10.99')
    end

    it 'replaces message with payment link' do
      expect(job.message_tag_replace('#{job-payment_request}')).to eq(ShortCode.last.to_s)
    end

    describe 'with payment info' do
      before do
        job.payments_received = 2.99
        job.save!
      end

      it 'replaces job-total_amount_paid' do
        expect(job.message_tag_replace('#{job-total_amount_paid}')).to eq('$2.99')
      end

      it 'replaces job-remaining_amount_due' do
        expect(job.message_tag_replace('#{job-remaining_amount_due}')).to eq('$10.99')
      end
    end

    it 'creates a short_code' do
      expect do
        job.message_tag_replace('#{job-payment_request}')
      end.to change { ShortCode.count }.from(0).to(1)
    end

    it 'creates the correct redirect' do
      job.message_tag_replace('#{job-payment_request}')
      expect(ShortCode.last.url).to eq "https://cardx.com/testaccount-asdf?accountIdentifier=#{contact.id}&amount=10.99&invoiceIdentifier=#{job.id}&name=Joe%20Tester&redirect=https%3A%2F%2Fapple.com%2F"
    end
  end
  # rubocop:enable Lint/InterpolationCheck
end
