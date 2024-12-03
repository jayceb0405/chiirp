# frozen_string_literal: true

# spec/lib/acceptable_time_spec.rb
# foreman run bundle exec rspec spec/lib/acceptable_time_spec.rb
require 'rails_helper'
describe Integrations::SendGrid::V1::Base do
  let(:sendgrid) { Integrations::SendGrid::V1::Base.new }
  let(:to_email) { 'twhwfnrbq9mhjdt9x5qk@chiirp.io' }
  let(:to) { "To: #{to_email}" }
  let(:from) { 'From: "Hwy 18, LLC Team" <forwarding-noreply@google.com>' }
  let(:from2) { 'From: Tester Joe <joe@tester.com>' }
  let(:from3) { 'From: "Tester Joe" <joe@tester.com>' }
  let(:from4) { 'From: <joe@tester.com>' }

  describe '#parse_email_addresses_from_headers' do
    let(:headers) { "#{from}\n#{to}" }

    it 'returns the correct email addresses' do
      expect(sendgrid.send(:parse_email_addresses_from_headers, headers)).to eq({
                                                                                  from: [{ email: 'forwarding-noreply@google.com', name: 'Hwy 18, LLC Team' }],
                                                                                  cc:   nil
                                                                                })
    end
  end

  describe '#parse_email_addresses' do
    it 'returns the correct email addresses' do
      expect(sendgrid.send(:parse_email_addresses, from)).to eq([{ email: 'forwarding-noreply@google.com', name: 'Hwy 18, LLC Team' }])
      expect(sendgrid.send(:parse_email_addresses, from2)).to eq([{ email: 'joe@tester.com', name: 'Tester Joe' }])
      expect(sendgrid.send(:parse_email_addresses, from3)).to eq([{ email: 'joe@tester.com', name: 'Tester Joe' }])
      expect(sendgrid.send(:parse_email_addresses, from4)).to eq([{ email: 'joe@tester.com', name: nil }])
    end
  end

  describe '#parse_email' do
    let(:headers) { "#{from}\n#{to}\nSubject: this is a test" }
    let(:mail) do
      {
        attachments: 0,
        envelope:    {
          to: [to_email]
        },
        headers:
      }
    end

    it 'returns the correct from address' do
      res = sendgrid.parse_email(mail)
      expect(res[:from]).to eq({ email: 'forwarding-noreply@google.com', name: 'Hwy 18, LLC Team' })
    end

    it 'returns the correct to address' do
      res = sendgrid.parse_email(mail)
      expect(res[:to].first).to eq({ email: 'twhwfnrbq9mhjdt9x5qk@chiirp.io', name: nil })
    end
  end
end
