# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Triggeraction do
  let(:client) { create :client }
  let(:email_template) { create :email_template, client: }
  let(:campaign) { create :campaign, client: }
  let(:trigger) { create :trigger, campaign: }
  let(:triggeraction) { create :triggeraction, trigger:, action_type: 170, email_template_id: email_template.id, to_email: contact.email }
  let(:contact) { create :contact, client:, email: 'asdf@chiirp.com' }
  let(:contact_campaign) { create :contact_campaign, contact:, campaign: triggeraction.trigger.campaign }
  let(:common_args) do
    {
      start_time: Time.current.beginning_of_minute,
      time_zone:  Time.current.zone,
      safe_sun:   true,
      safe_mon:   true,
      safe_tue:   true,
      safe_wed:   true,
      safe_thu:   true,
      safe_fri:   true,
      safe_sat:   true
    }
  end

  describe '#fire_triggeraction_170' do
    let(:email_integration) { create :client_api_integration_for_sendgrid, client: }

    before do
      email_integration
    end

    it 'should send an email' do
      contact_delay = double('contact_delay')
      expect(contact_delay).to receive(:send_email)
      expect(contact).to receive(:delay) do |args|
        expect(args[:data][:email_template_id]).to eq(email_template.id)
        expect(args[:data][:to_email]).to eq(contact.email)
      end.and_return(contact_delay)
      triggeraction.fire_triggeraction_170(contact:, contact_campaign:, common_args:)
    end
  end

  describe '#copy' do
    let(:new_trigger) { create :trigger }

    before do
      email_template
    end

    it 'should create a new email template' do
      expect do
        triggeraction.copy(new_trigger_id: new_trigger.id)
      end.to change { EmailTemplate.count }.from(1).to(2)
    end

    it 'should set email_template_id' do
      triggeraction.copy(new_trigger_id: new_trigger.id)
      expect(new_trigger.triggeractions.last.email_template_id).to eq(EmailTemplate.where.not(id: email_template.id).limit(1).first.id)
    end
  end
end
