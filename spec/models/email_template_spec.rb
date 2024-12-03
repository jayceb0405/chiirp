# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EmailTemplate do
  let(:email_template) { create :email_template }

  describe 'copy' do
    describe 'within the same client' do
      before do
        email_template
      end

      it 'creates a new record' do
        expect do
          email_template.copy(new_client_id: email_template.client_id, campaign_id_prefix: nil)
        end.to change { EmailTemplate.count }.from(1).to(2)
      end

      it 'keeps the same client id' do
        new_template = email_template.copy(new_client_id: email_template.client_id, campaign_id_prefix: nil)
        expect(new_template.client_id).to eq(email_template.client_id)
      end
    end

    describe 'with a new client' do
      let(:client2) { create :client }
      before do
        email_template
      end

      it 'creates a new record' do
        expect do
          email_template.copy(new_client_id: email_template.client_id, campaign_id_prefix: nil)
        end.to change { EmailTemplate.count }.from(1).to(2)
      end

      it 'uses the new client id' do
        new_template = email_template.copy(new_client_id: client2.id, campaign_id_prefix: nil)
        expect(new_template.client_id).to eq(client2.id)
      end
    end

    describe 'with a trackable link' do
      let(:client2) { create :client }
      let(:trackable_link) { create :trackable_link, client: email_template.client }
      before do
        email_template.update content: "\#{trackable_link_#{trackable_link.id}}"
      end

      it 'creates a new record' do
        expect do
          email_template.copy(new_client_id: client2.id, campaign_id_prefix: nil)
        end.to change { EmailTemplate.count }.from(1).to(2)
      end

      it 'uses the new client id' do
        new_template = email_template.copy(new_client_id: client2.id, campaign_id_prefix: nil)
        expect(new_template.client_id).to eq(client2.id)
      end

      it 'creates a new trackable link' do
        expect do
          email_template.copy(new_client_id: client2.id, campaign_id_prefix: nil)
        end.to change { TrackableLink.count }.from(1).to(2)
      end

      it 'updates the content with the new trackable link id' do
        new_template = email_template.copy(new_client_id: client2.id, campaign_id_prefix: nil)
        new_trackable_link = TrackableLink.where.not(id: trackable_link.id).last

        expect(new_template.content).to eq("\#{trackable_link_#{new_trackable_link.id}}")
      end
    end
  end
end
