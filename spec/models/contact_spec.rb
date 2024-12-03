# frozen_string_literal: true

# foreman run bundle exec rspec spec/models/contact_spec.rb
require 'rails_helper'

RSpec.describe Contact do
  let(:client_api_integration) { create :client_api_integration_for_cardx }
  let(:client) { client_api_integration.client }
  let(:contact) { create :contact_with_companynmame, client: }

  # rubocop:disable Lint/InterpolationCheck
  describe 'message_tag_replace' do
    it 'replaces firstname' do
      expect(contact.message_tag_replace('#{firstname}')).to eq(contact.firstname)
    end

    it 'replaces lastname' do
      expect(contact.message_tag_replace('#{lastname}')).to eq(contact.lastname)
    end

    it 'replaces message with payment link without hashtag' do
      expect(contact.message_tag_replace('', payment_request: 12.99)).to eq("\n#{ShortCode.last}")
    end

    it 'replaces message with payment link' do
      expect(contact.message_tag_replace('#{request_payment_link}')).to eq(ShortCode.last.to_s)
    end

    it 'replaces contact company name' do
      expect(contact.message_tag_replace('#{companyname}')).to eq(contact.companyname)
      expect(contact.message_tag_replace('#{contact-company-name}')).to eq(contact.companyname)
    end

    it 'replaces client company name' do
      expect(contact.message_tag_replace('#{c-name}')).to eq(client.name)
      expect(contact.message_tag_replace('#{my-company-name}')).to eq(client.name)
    end

    it 'creates a short_code' do
      expect do
        contact.message_tag_replace('#{request_payment_link}')
      end.to change { ShortCode.count }.from(0).to(1)
    end

    it 'creates the correct redirect' do
      contact.message_tag_replace('#{request_payment_link}')
      expect(ShortCode.last.url).to eq "https://cardx.com/testaccount-asdf?accountIdentifier=#{contact.id}&name=Joe%20Tester&redirect=https%3A%2F%2Fapple.com%2F"
    end

    it 'creates the correct redirect' do
      contact.message_tag_replace('#{request_payment_link}', payment_request: 12.99)
      expect(ShortCode.last.url).to eq "https://cardx.com/testaccount-asdf?accountIdentifier=#{contact.id}&amount=12.99&name=Joe%20Tester&redirect=https%3A%2F%2Fapple.com%2F"
    end
  end

  describe 'update_contact_phones' do
    let(:contact_phone) { create :contact_phone, contact: }

    before do
      contact_phone
      contact.reload
    end

    it 'verifies contact_phone' do
      expect(contact.contact_phones.first.phone).to eq('9123450098')
      expect(contact.contact_phones.length).to eq(1)
    end

    it 'verifies adding 2 phone numbers while designating a primary number' do
      contact.update_contact_phones([['9123450098', 'mobile', true], ['8002345782', 'work', false]])
      expect(contact.contact_phones.first.phone).to eq('9123450098')
      expect(contact.contact_phones.last.phone).to eq('8002345782')
      expect(contact.contact_phones.length).to eq(2)
    end

    it 'verifies adding 2 phone numbers while not designating a primary number' do
      contact.update_contact_phones([%w[9123450098 mobile], %w[8002345782 work]])
      expect(contact.primary_phone&.phone).to eq('9123450098')
      expect(contact.contact_phones.length).to eq(2)
    end

    it 'verifies deleting 1 number' do
      contact.update_contact_phones([['9123450098', 'mobile', true], ['8002345782', 'work', false]])
      contact.update_contact_phones([['9123450098', 'mobile', true]], true)
      contact.reload
      expect(contact.contact_phones.first.phone).to eq('9123450098')
      expect(contact.contact_phones.length).to eq(1)
    end

    it 'verifies updating 1 phone number and not designating primary while update_primary = true' do
      contact.update_contact_phones([['9123450098', 'mobile', true], ['8002345782', 'work', false]])
      contact.update_contact_phones([['8002345782', 'work', false]], false, true)
      expect(contact.primary_phone&.phone).to eq('9123450098')
      expect(contact.contact_phones.length).to eq(2)
    end

    it 'verifies updating 1 phone number and designating primary while update_primary = true' do
      contact.update_contact_phones([['9123450098', 'mobile', true], ['8002345782', 'work', false]])
      contact.update_contact_phones([['8002345782', 'work', true]], false, true)
      expect(contact.primary_phone&.phone).to eq('8002345782')
      expect(contact.contact_phones.length).to eq(2)
    end

    it 'verifies updating 1 phone number and not designating primary while update_primary = false' do
      contact.update_contact_phones([['9123450098', 'mobile', true], ['8002345782', 'work', false]])
      contact.update_contact_phones([['8002345782', 'work', false]], false)
      expect(contact.primary_phone&.phone).to eq('9123450098')
      expect(contact.contact_phones.length).to eq(2)
    end

    it 'verifies updating 1 phone number and designating primary while update_primary = false' do
      contact.update_contact_phones([['9123450098', 'mobile', true], ['8002345782', 'work', false]])
      contact.update_contact_phones([['8002345782', 'work', true]], false)
      expect(contact.primary_phone&.phone).to eq('9123450098')
      expect(contact.contact_phones.length).to eq(2)
    end
  end
  # rubocop:enable Lint/InterpolationCheck

  describe 'stop_and_start_contact_campaigns' do
    let(:campaign) { create(:campaign_with_trigger_and_action, client:) }
    let(:params) do
      {
        contact_estimate_id: 0, contact_invoice_id: 0, contact_job_id: 0, contact_visit_id: 0, st_membership_id: 0
      }
    end

    before do
      # the following is a workaround to avoid the following errors. For some reason the Delayed::Job is not clearing out with each test.
      # expected to enqueue exactly 1 jobs, but enqueued 2
      # expected to enqueue exactly 1 jobs, but enqueued 3
      # expected to enqueue exactly 1 jobs, but enqueued 4
      expect(Contacts::Campaigns::StartJob).to receive(:perform_later)
    end

    it 'should call start_campaign' do
      # expect(contact).to receive(:stop_contact_campaigns).with(campaign_id: 'all')
      contact.stop_and_start_contact_campaigns(stop_campaign_ids: ['0'], start_campaign_id: campaign.id)
    end

    it 'should call stop_contact_campaigns with all' do
      # expect(contact).to receive(:stop_contact_campaigns).with(campaign_id: 'all')
      contact.stop_and_start_contact_campaigns(stop_campaign_ids: ['0'], start_campaign_id: campaign.id)
    end

    it 'should call stop_contact_campaigns with id' do
      # expect(contact).to receive(:stop_contact_campaigns).with(campaign_id: 1)
      contact.stop_and_start_contact_campaigns(stop_campaign_ids: ['1'], start_campaign_id: campaign.id)
    end

    it 'should call stop_contact_campaigns with multiple ids' do
      # expect(contact).to receive(:stop_contact_campaigns).with(campaign_id: 1)
      # expect(contact).to receive(:stop_contact_campaigns).with(campaign_id: 2)
      contact.stop_and_start_contact_campaigns(stop_campaign_ids: ['1', 2], start_campaign_id: campaign.id)
    end
  end
end
