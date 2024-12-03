# frozen_string_literal: true

require 'rails_helper'

# foreman run bundle exec rspec spec/requests/integrations/cardx/integrations_request_spec.rb
RSpec.describe Integrations::Cardx::IntegrationsController, type: :request do
  let(:client) { create :client }
  let(:contact) { create :contact_with_email, client: }
  let(:job) { create :job, contact: }
  let(:campaign) { create :campaign_with_trigger_and_action, client: }
  let(:client_api_integration) { create :client_api_integration_for_cardx, campaign:, client: }
  let(:params_new_contact) do
    {
      'pt_gateway_account'       => 'chiirptst',
      'pt_payment_name'          => 'Joe Tester',
      'pt_billing_email_address' => 'asdf@asdf.com',
      'pt_billing_city'          => 'Everett',
      'pt_billing_state'         => 'WA',
      'pt_transaction_amount'    => 12.99,
      'pt_authorization_code'    => 'AUTHTST',
      'date'                     => '2023-02-16 21:35:56'
    }
  end
  let(:params_existing_contact) do
    {
      'pt_gateway_account'       => 'chiirptst',
      'pt_payment_name'          => 'Joe Tester',
      'pt_billing_email_address' => contact.email,
      'pt_billing_city'          => 'Everett',
      'pt_billing_state'         => 'WA',
      'pt_transaction_amount'    => job.total_amount,
      'pt_authorization_code'    => 'AUTHTST',
      'date'                     => '2023-02-16 21:35:56',
      'pt_account_code_1'        => contact.id,
      'pt_account_code_2'        => job.id
    }
  end
  let(:headers) do
    {
      Integrations::Cardx::IntegrationsController::HTTP_REQUEST_HEADER_KEY => client_api_integration.webhook_header_token
    }
  end

  around do |example|
    perform_enqueued_jobs do
      example.run
    end
  end

  it 'returns unauthorized' do
    post integrations_cardx_endpoint_path(client_api_integration.webhook_api_key)

    expect(response).to have_http_status(:unauthorized)
  end

  it 'returns no content' do
    post(integrations_cardx_endpoint_path(client_api_integration.webhook_api_key), params: params_new_contact, headers:)

    expect(response).to have_http_status(:no_content)
  end

  # it 'adds a contact' do
  #   expect do
  #     post(integrations_cardx_endpoint_path(client_api_integration.webhook_api_key), params: params_new_contact, headers:)
  #   end.to change { Contact.count }.from(0).to(1)

  #   expect(Contact.first.email).to eq('asdf@asdf.com')
  #   expect(Contact.first.firstname).to eq('Joe')
  #   expect(Contact.first.lastname).to eq('Tester')
  #   expect(Contact.first.city).to eq('Everett')
  #   expect(Contact.first.state).to eq('WA')
  # end

  it 'starts a campaign' do
    expect do
      post(integrations_cardx_endpoint_path(client_api_integration.webhook_api_key), params: params_existing_contact, headers:)
    end.to change { campaign.contact_campaigns.count }.from(0).to(1)
  end

  it 'sends contact job id to campaign' do
    expect_any_instance_of(Contact).to receive(:process_actions).with({ campaign_id: campaign.id, contact_job_id: job.id, group_id: 0, stage_id: 0, tag_id: 0, stop_campaign_ids: nil })
    post(integrations_cardx_endpoint_path(client_api_integration.webhook_api_key), params: params_existing_contact, headers:)
  end

  describe 'with 5.0 remaining balance' do
    tests = []
    tests << { remaining_balance_operator: 'gte', remaining_balance: 6.0, result: false }
    tests << { remaining_balance_operator: 'gte', remaining_balance: 5.0, result: true }
    tests << { remaining_balance_operator: 'lte', remaining_balance: 5.0, result: true }
    tests << { remaining_balance_operator: 'lte', remaining_balance: 4.0, result: false }

    tests.each do |test|
      it "handles remaining_balance_operator:#{test[:remaining_balance_operator]} remaining_balance:#{test[:remaining_balance]}" do
        new_param = params_existing_contact.tap do |hash|
          hash['pt_transaction_amount'] = job.total_amount - 5.0
        end

        client_api_integration.events = [
          {
            event_id:                   'asg2435',
            name:                       'asdf',
            remaining_balance_operator: test[:remaining_balance_operator],
            remaining_balance:          test[:remaining_balance],
            action:                     {
              campaign_id: campaign.id
            }
          }
        ]
        client_api_integration.save!

        expect do
          post(integrations_cardx_endpoint_path(client_api_integration.webhook_api_key), params: new_param, headers:)
        end.to change { campaign.contact_campaigns.count }.by(test[:result] ? 1 : 0)
      end
    end
  end

  it 'saves raw post data' do
    expect do
      post(integrations_cardx_endpoint_path(client_api_integration.webhook_api_key), params: params_existing_contact, headers:)
    end.to change { Contacts::RawPost.count }.from(0).to(1)
    Contacts::RawPost.last.tap do |raw_post|
      expect(raw_post.ext_source).to eq 'cardx'
      expect(raw_post.ext_id).to eq 'payment'
      expect(raw_post.data['pt_billing_email_address']).to eq contact.email
    end
  end

  # TODO: this is ugly.
  it 'updates Service Titan' do
    create(:client_api_integration_for_servicetitan, client:)

    service_titan_model = double('service titan model')
    allow(service_titan_model).to receive(:valid_credentials?).and_return(true)
    allow(Integration::Servicetitan::V2::Base).to receive(:new).and_return(service_titan_model)

    service_titan_base = double('service titan base')
    payment_data = {
      amount_paid:   params_existing_contact['pt_transaction_amount'],
      auth_code:     params_existing_contact['pt_authorization_code'],
      comment:       client_api_integration.service_titan['comment'],
      paid_at:       Time.parse(params_existing_contact['date']),
      st_invoice_id: job.ext_invoice_id,
      st_type_id:    client_api_integration.service_titan['payment_type']
    }
    expect(service_titan_base).to receive(:post_payment).with(payment_data).and_return(true)
    allow(Integrations::ServiceTitan::Base).to receive(:new).and_return(service_titan_base)

    post(integrations_cardx_endpoint_path(client_api_integration.webhook_api_key), params: params_existing_contact, headers:)
  end

  # TODO: this is ugly. it requires knowledge of the implementation details. but it tests to ensure the method isn't called when not needed for now.
  it 'does not update Service Titan' do
    expect(Integration::Servicetitan::V2::Base).not_to receive(:new)
    post(integrations_cardx_endpoint_path(client_api_integration.webhook_api_key), params: params_existing_contact, headers:)
  end
end
