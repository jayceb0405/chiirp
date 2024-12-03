# frozen_string_literal: true

# spec/lib/integrations/card_x/base_spec.rb
# foreman run bundle exec rspec spec/lib/integrations/card_x/base_spec.rb
require 'rails_helper'
RSpec.describe Integrations::CardX::Base, type: :model do
  describe 'lightbox_url' do
    let(:client) { Integrations::CardX::Base.new('account') }

    it 'creates a url with no params' do
      expect(client.lightbox_url).to eq 'https://cardx.com/testaccount-account'
    end

    it 'creates a url with amount' do
      expect(client.lightbox_url(amount: 10.22)).to eq 'https://cardx.com/testaccount-account?amount=10.22'
    end

    it 'creates a url with name' do
      expect(client.lightbox_url(name: 'tester joe')).to eq 'https://cardx.com/testaccount-account?name=tester%20joe'
    end

    it 'creates a url with zip' do
      expect(client.lightbox_url(zip: '92646')).to eq 'https://cardx.com/testaccount-account?billingZip=92646'
    end

    it 'creates a url with email' do
      expect(client.lightbox_url(email: 'asdf@asdf.com')).to eq 'https://cardx.com/testaccount-account?billingEmail=asdf%40asdf.com'
    end

    it 'creates a url with redirect' do
      expect(client.lightbox_url(redirect: 'https://www.google.com/')).to eq 'https://cardx.com/testaccount-account?redirect=https%3A%2F%2Fwww.google.com%2F'
    end

    it 'creates a url with an invoice id' do
      expect(client.lightbox_url(job_id: 'asdf101')).to eq 'https://cardx.com/testaccount-account?invoiceIdentifier=asdf101'
    end

    it 'creates a url with an account id' do
      expect(client.lightbox_url(contact_id: 123_456)).to eq 'https://cardx.com/testaccount-account?accountIdentifier=123456'
    end
  end
end
