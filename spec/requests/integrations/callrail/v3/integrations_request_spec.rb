# frozen_string_literal: true

# foreman run bundle exec rspec spec/requests/integrations/callrail/v3/integrations_request_spec.rb
require 'rails_helper'

RSpec.describe Integrations::Callrail::V3::IntegrationsController, type: :request do
  let(:params) do
    params = JSON.parse(body_original_string)
    params[:timestamp] = Time.current.iso8601
    params.to_json
  end
  let(:headers) { { 'signature' => signature, 'Content-Type' => 'application/json' } }
  let(:signature) do
    Base64.strict_encode64(
      OpenSSL::HMAC.digest(
        'sha1',
        client_api_integration.credentials['webhook_signature_token'],
        params
      )
    )
  end
  let(:client) { create :client }
  let(:campaign) { create :campaign_with_trigger_and_action, client: }
  let(:client_api_integration) { create :client_api_integration_for_callrail, campaign:, client: }

  around do |example|
    perform_enqueued_jobs do
      example.run
    end
  end

  it 'returns unauthorized' do
    post integrations_callrail_v3_endpoint_path(client_api_integration.webhook_api_key)

    expect(response).to have_http_status(:unauthorized)
  end

  describe 'with post call webhook' do
    let(:body_original_string) { '{"answered":false,"business_phone_number":"+18022823191","call_type":"abandoned","company_id":422269185,"company_name":"Hwy 18, LLC (Chiirp)","company_time_zone":"America/Detroit","created_at":"2022-12-13T16:54:58.563-05:00","customer_city":"Laguna Beach","customer_country":"US","customer_name":"Laguna Beach Ca","customer_phone_number":"+19494846382","customer_state":"CA","device_type":"","direction":"inbound","duration":"15","first_call":false,"formatted_call_type":"Abandoned Call","formatted_customer_location":"Laguna Beach, CA","formatted_business_phone_number":"802-282-3191","formatted_customer_name":"Laguna Beach Ca","prior_calls":1,"formatted_customer_name_or_phone_number":"Laguna Beach Ca","formatted_customer_phone_number":"949-484-6382","formatted_duration":"(abandoned)","formatted_tracking_phone_number":"802-392-9680","formatted_tracking_source":"Unknown Source","formatted_value":"--","good_lead_call_id":"","good_lead_call_time":"","lead_status":"","note":"","recording":"","recording_duration":"","source":"Unknown Source","source_name":"Website Pool","start_time":"2022-12-13T16:54:53.505-05:00","tags":["goodtag"],"detail_tags":[],"total_calls":2,"tracking_phone_number":"+18023929680","transcription":"","value":"","voicemail":false,"waveforms":"","keywords":"superasdf test","medium":"","referring_url":"","landing_page_url":"","last_requested_url":"","milestones":{"first_touch":{"event_date":"2022-12-13T16:01:57.985-05:00","ad_position":null,"campaign":null,"device":null,"keywords":null,"landing":null,"landing_page_url_params":{},"match_type":null,"medium":null,"referrer":null,"referrer_url_params":{},"session_browser":null,"url_utm_params":{},"source":"Unknown Source"},"lead_created":{"event_date":"2022-12-13T16:01:57.985-05:00","ad_position":null,"campaign":null,"device":null,"keywords":null,"landing":null,"landing_page_url_params":{},"match_type":null,"medium":null,"referrer":null,"referrer_url_params":{},"session_browser":null,"url_utm_params":{},"source":"Unknown Source"}},"referrer_domain":"","conversational_transcript":"","utm_source":"","utm_medium":"","utm_term":"","utm_content":"","utm_campaign":"","utma":"","utmb":"","utmc":"","utmv":"","utmz":"","ga":"","fbclid":"","gclid":"","integration_data":[{"integration":"Webhooks","data":null}],"keywords_spotted":"","recording_player":"","speaker_percent":"","call_highlights":[],"agent_email":"","campaign":"","msclkid":"","keypad_entries":"","recording_redirect":"","spam":false,"timeline_url":"https://app.callrail.com/analytics/a/728790660/events/PER104f23341f5f4052b19bfc789487503e?event_id=CAL09c8a75d189149a482e881a9590ac1ba\u0026event_type=call","custom":"","callercity":"Laguna Beach","callercountry":"US","callername":"Laguna Beach Ca","callernum":"+19494846382","callerstate":"CA","callsource":"keyword","datetime":"2022-12-13 21:54:53","destinationnum":"+18022823191","kissmetrics_id":"","landingpage":"","referrer":"","referrermedium":"","score":"","tag":"","trackingnum":"+18023929680","timestamp":"2022-12-13T16:54:53.505-05:00","person_resource_id":"PER104f23341f5f4052b19bfc789487503e","resource_id":"CAL09c8a75d189149a482e881a9590ac1ba","company_resource_id":"COMdcdc6f0d953941e8bebbd8bf22a03662","tracker_resource_id":"TRKe19ca8369ac44cddbf11db016414870b"}' }

    it 'returns no content' do
      post(integrations_callrail_v3_endpoint_path(client_api_integration.webhook_api_key, type: 'inbound_post_call'), params:, headers:)

      expect(response).to have_http_status(:no_content)
    end

    it 'processes a webhook event' do
      expect do
        post(integrations_callrail_v3_endpoint_path(client_api_integration.webhook_api_key, type: 'inbound_post_call'), params:, headers:)
      end.to change { Contact.count }.from(0).to(1)
      expect(Contact.last.firstname).to eq('Laguna')
      expect(Contact.last.city).to eq('Laguna Beach')
      expect(Contact.last.state).to eq('CA')
      expect(Contact.last.tags.count).to eq(1)
      expect(campaign.contact_campaigns.count).to eq(1)
    end

    it 'processes a webhook event without type' do
      expect do
        post(integrations_callrail_v3_endpoint_path(client_api_integration.webhook_api_key), params:, headers:)
      end.to change { Contact.count }.from(0).to(1)
      expect(Contact.last.firstname).to eq('Laguna')
      expect(Contact.last.city).to eq('Laguna Beach')
      expect(Contact.last.state).to eq('CA')
      expect(Contact.last.tags.count).to eq(1)
      expect(campaign.contact_campaigns.count).to eq(1)
    end

    it 'creates a raw post record' do
      expect do
        post(integrations_callrail_v3_endpoint_path(client_api_integration.webhook_api_key, type: 'inbound_post_call'), params:, headers:)
      end.to change { Contacts::RawPost.count }.from(0).to(1)
      Contacts::RawPost.last.tap do |raw_post|
        expect(raw_post.ext_source).to eq 'callrail'
        expect(raw_post.ext_id).to eq 'callcompleted'
        expect(raw_post.data['call_type']).to eq 'abandoned'
      end
    end

    describe 'with an excluded tag' do
      let(:body_original_string) { '{"answered":false,"business_phone_number":"+18022823191","call_type":"abandoned","company_id":422269185,"company_name":"Hwy 18, LLC (Chiirp)","company_time_zone":"America/Detroit","created_at":"2022-12-13T16:54:58.563-05:00","customer_city":"Laguna Beach","customer_country":"US","customer_name":"Laguna Beach Ca","customer_phone_number":"+19494846382","customer_state":"CA","device_type":"","direction":"inbound","duration":"15","first_call":false,"formatted_call_type":"Abandoned Call","formatted_customer_location":"Laguna Beach, CA","formatted_business_phone_number":"802-282-3191","formatted_customer_name":"Laguna Beach Ca","prior_calls":1,"formatted_customer_name_or_phone_number":"Laguna Beach Ca","formatted_customer_phone_number":"949-484-6382","formatted_duration":"(abandoned)","formatted_tracking_phone_number":"802-392-9680","formatted_tracking_source":"Unknown Source","formatted_value":"--","good_lead_call_id":"","good_lead_call_time":"","lead_status":"","note":"","recording":"","recording_duration":"","source":"Unknown Source","source_name":"Website Pool","start_time":"2022-12-13T16:54:53.505-05:00","tags":["badtag"],"detail_tags":[],"total_calls":2,"tracking_phone_number":"+18023929680","transcription":"","value":"","voicemail":false,"waveforms":"","keywords":"superasdf test","medium":"","referring_url":"","landing_page_url":"","last_requested_url":"","milestones":{"first_touch":{"event_date":"2022-12-13T16:01:57.985-05:00","ad_position":null,"campaign":null,"device":null,"keywords":null,"landing":null,"landing_page_url_params":{},"match_type":null,"medium":null,"referrer":null,"referrer_url_params":{},"session_browser":null,"url_utm_params":{},"source":"Unknown Source"},"lead_created":{"event_date":"2022-12-13T16:01:57.985-05:00","ad_position":null,"campaign":null,"device":null,"keywords":null,"landing":null,"landing_page_url_params":{},"match_type":null,"medium":null,"referrer":null,"referrer_url_params":{},"session_browser":null,"url_utm_params":{},"source":"Unknown Source"}},"referrer_domain":"","conversational_transcript":"","utm_source":"","utm_medium":"","utm_term":"","utm_content":"","utm_campaign":"","utma":"","utmb":"","utmc":"","utmv":"","utmz":"","ga":"","fbclid":"","gclid":"","integration_data":[{"integration":"Webhooks","data":null}],"keywords_spotted":"","recording_player":"","speaker_percent":"","call_highlights":[],"agent_email":"","campaign":"","msclkid":"","keypad_entries":"","recording_redirect":"","spam":false,"timeline_url":"https://app.callrail.com/analytics/a/728790660/events/PER104f23341f5f4052b19bfc789487503e?event_id=CAL09c8a75d189149a482e881a9590ac1ba\u0026event_type=call","custom":"","callercity":"Laguna Beach","callercountry":"US","callername":"Laguna Beach Ca","callernum":"+19494846382","callerstate":"CA","callsource":"keyword","datetime":"2022-12-13 21:54:53","destinationnum":"+18022823191","kissmetrics_id":"","landingpage":"","referrer":"","referrermedium":"","score":"","tag":"","trackingnum":"+18023929680","timestamp":"2022-12-13T16:54:53.505-05:00","person_resource_id":"PER104f23341f5f4052b19bfc789487503e","resource_id":"CAL09c8a75d189149a482e881a9590ac1ba","company_resource_id":"COMdcdc6f0d953941e8bebbd8bf22a03662","tracker_resource_id":"TRKe19ca8369ac44cddbf11db016414870b"}' }

      it 'does not process an event' do
        expect do
          post(integrations_callrail_v3_endpoint_path(client_api_integration.webhook_api_key, type: 'inbound_post_call'), params:, headers:)
        end.to change { Contact.count }.from(0).to(1)
        expect(Contact.last.firstname).to eq('Laguna')
        expect(Contact.last.city).to eq('Laguna Beach')
        expect(Contact.last.state).to eq('CA')
        expect(Contact.last.tags.count).to eq(1)
        expect(campaign.contact_campaigns.count).to eq(0)
      end
    end
  end

  describe 'with outbound post call webhook' do
    let(:body_original_string) { '{"answered":"false","business_phone_number":"+19494846382","call_type":"outbound","company_id":347661122,"company_name":"Asdf Test","company_time_zone":"America/New_York","created_at":"2023-01-24T17:53:25.337-05:00","customer_city":"Huntington Beach","customer_country":"US","customer_name":"Joe Tester","customer_phone_number":"+17144758933","customer_state":"CA","device_type":"","direction":"outbound","duration":"0","first_call":"false","formatted_call_type":"Outbound Call","formatted_customer_location":"Huntington Beach, CA","formatted_business_phone_number":"949-484-6382","formatted_customer_name":"Joe Tester","prior_calls":1,"formatted_customer_name_or_phone_number":"Joe Tester","formatted_customer_phone_number":"714-555-1212","formatted_duration":"(abandoned)","formatted_tracking_phone_number":"949-303-7465","formatted_tracking_source":"Radio Ad","formatted_value":"--","good_lead_call_id":"","good_lead_call_time":"","lead_status":"","note":"","recording":"","recording_duration":"","source":"Radio Ad","source_name":"Radio Ad","start_time":"2023-01-24T17:53:25.443-05:00","tags":["goodtag","asdf"],"detail_tags":[],"total_calls":2,"tracking_phone_number":"+19493037465","transcription":"","value":"","voicemail":false,"waveforms":"","keywords":"asdf","medium":"direct","referring_url":"","landing_page_url":"","last_requested_url":"","milestones":{"first_touch":{"event_date":"2023-01-24T16:14:13.745-05:00","ad_position":null,"campaign":null,"device":null,"keywords":null,"landing":null,"landing_page_url_params":{},"match_type":null,"medium":"direct","referrer":null,"referrer_url_params":{},"session_browser":null,"url_utm_params":{},"source":"Radio Ad"},"lead_created":{"event_date":"2023-01-24T16:14:13.745-05:00","ad_position":null,"campaign":null,"device":null,"keywords":null,"landing":null,"landing_page_url_params":{},"match_type":null,"medium":"direct","referrer":null,"referrer_url_params":{},"session_browser":null,"url_utm_params":{},"source":"Radio Ad"}},"referrer_domain":"","conversational_transcript":"","utm_source":"offline","utm_medium":"direct","utm_term":"","utm_content":"","utm_campaign":"Radio Ad","utma":"","utmb":"","utmc":"","utmv":"","utmz":"","ga":"","fbclid":"","gclid":"","integration_data":[{"integration":"Webhooks","data":null}],"keywords_spotted":"","recording_player":"","speaker_percent":"","call_highlights":[],"agent_email":"ian@ianneubert.com","campaign":"","msclkid":"","keypad_entries":"","recording_redirect":"","spam":false,"timeline_url":"https://app.callrail.com/analytics/a/728790660/events/PERafc378245bd8453094bea49df5bc9ae9?event_id=CALd093946bec9743b2a822cd4e4240a471&event_type=call","custom":"","callercity":"Huntington Beach","callercountry":"US","callername":"Joe Tester","callernum":"+17144758933","callerstate":"CA","callsource":"disabled","datetime":"2023-01-24 22:53:25","destinationnum":"+19494846382","kissmetrics_id":"","landingpage":"","referrer":"","referrermedium":"direct","score":"","tag":"","trackingnum":"+19493037465","timestamp":"2023-01-24T17:53:25.443-05:00","person_resource_id":"PERafc378245bd8453094bea49df5bc9ae9","resource_id":"CALd093946bec9743b2a822cd4e4240a471","company_resource_id":"COMdcdc6f0d953941e8bebbd8bf22a03662","tracker_resource_id":"TRK2989a8b2cf0d49d0a03e8cc26f1b8af5","type":"outboundpostcall"}' }

    it 'returns no content' do
      post(integrations_callrail_v3_endpoint_path(client_api_integration.webhook_api_key, type: 'outbound_post_call'), params:, headers:)

      expect(response).to have_http_status(:no_content)
    end

    it 'processes a webhook event' do
      expect do
        post(integrations_callrail_v3_endpoint_path(client_api_integration.webhook_api_key, type: 'outbound_post_call'), params:, headers:)
      end.to change { Contact.count }.from(0).to(1)
      expect(Contact.last.firstname).to eq('Joe')
      expect(campaign.contact_campaigns.count).to eq(1)
    end

    it 'creates a raw post record' do
      expect do
        post(integrations_callrail_v3_endpoint_path(client_api_integration.webhook_api_key, type: 'outbound_post_call'), params:, headers:)
      end.to change { Contacts::RawPost.count }.from(0).to(1)
      Contacts::RawPost.last.tap do |raw_post|
        expect(raw_post.ext_source).to eq 'callrail'
        expect(raw_post.ext_id).to eq 'callcompleted'
        expect(raw_post.data['person_resource_id']).to eq 'PERafc378245bd8453094bea49df5bc9ae9'
      end
    end

    describe 'answered call' do
      let(:body_original_string) { '{"answered":"true","business_phone_number":"+19494846382","call_type":"outbound","company_id":347661122,"company_name":"Asdf Test","company_time_zone":"America/New_York","created_at":"2023-01-24T17:53:25.337-05:00","customer_city":"Huntington Beach","customer_country":"US","customer_name":"Joe Tester","customer_phone_number":"+17144758933","customer_state":"CA","device_type":"","direction":"outbound","duration":"0","first_call":"false","formatted_call_type":"Outbound Call","formatted_customer_location":"Huntington Beach, CA","formatted_business_phone_number":"949-484-6382","formatted_customer_name":"Joe Tester","prior_calls":1,"formatted_customer_name_or_phone_number":"Joe Tester","formatted_customer_phone_number":"714-555-1212","formatted_duration":"(abandoned)","formatted_tracking_phone_number":"949-303-7465","formatted_tracking_source":"Radio Ad","formatted_value":"--","good_lead_call_id":"","good_lead_call_time":"","lead_status":"","note":"","recording":"","recording_duration":"","source":"Radio Ad","source_name":"Radio Ad","start_time":"2023-01-24T17:53:25.443-05:00","tags":["goodtag","asdf"],"detail_tags":[],"total_calls":2,"tracking_phone_number":"+19493037465","transcription":"","value":"","voicemail":false,"waveforms":"","keywords":"asdf","medium":"direct","referring_url":"","landing_page_url":"","last_requested_url":"","milestones":{"first_touch":{"event_date":"2023-01-24T16:14:13.745-05:00","ad_position":null,"campaign":null,"device":null,"keywords":null,"landing":null,"landing_page_url_params":{},"match_type":null,"medium":"direct","referrer":null,"referrer_url_params":{},"session_browser":null,"url_utm_params":{},"source":"Radio Ad"},"lead_created":{"event_date":"2023-01-24T16:14:13.745-05:00","ad_position":null,"campaign":null,"device":null,"keywords":null,"landing":null,"landing_page_url_params":{},"match_type":null,"medium":"direct","referrer":null,"referrer_url_params":{},"session_browser":null,"url_utm_params":{},"source":"Radio Ad"}},"referrer_domain":"","conversational_transcript":"","utm_source":"offline","utm_medium":"direct","utm_term":"","utm_content":"","utm_campaign":"Radio Ad","utma":"","utmb":"","utmc":"","utmv":"","utmz":"","ga":"","fbclid":"","gclid":"","integration_data":[{"integration":"Webhooks","data":null}],"keywords_spotted":"","recording_player":"","speaker_percent":"","call_highlights":[],"agent_email":"ian@ianneubert.com","campaign":"","msclkid":"","keypad_entries":"","recording_redirect":"","spam":false,"timeline_url":"https://app.callrail.com/analytics/a/728790660/events/PERafc378245bd8453094bea49df5bc9ae9?event_id=CALd093946bec9743b2a822cd4e4240a471&event_type=call","custom":"","callercity":"Huntington Beach","callercountry":"US","callername":"Joe Tester","callernum":"+17144758933","callerstate":"CA","callsource":"disabled","datetime":"2023-01-24 22:53:25","destinationnum":"+19494846382","kissmetrics_id":"","landingpage":"","referrer":"","referrermedium":"direct","score":"","tag":"","trackingnum":"+19493037465","timestamp":"2023-01-24T17:53:25.443-05:00","person_resource_id":"PERafc378245bd8453094bea49df5bc9ae9","resource_id":"CALd093946bec9743b2a822cd4e4240a471","company_resource_id":"COMdcdc6f0d953941e8bebbd8bf22a03662","tracker_resource_id":"TRK2989a8b2cf0d49d0a03e8cc26f1b8af5","type":"outboundpostcall"}' }

      it 'does not process answered calls' do
        expect do
          post(integrations_callrail_v3_endpoint_path(client_api_integration.webhook_api_key, type: 'outbound_post_call'), params:, headers:)
        end.to change { Contact.count }.from(0).to(1)
        expect(Contact.last.firstname).to eq('Joe')
        expect(campaign.contact_campaigns.count).to eq(0)
      end
    end

    describe 'no answered setting' do
      it 'processes unanswered calls' do
        client_api_integration.events.second.delete('answered')
        client_api_integration.update! events: client_api_integration.events

        expect do
          post(integrations_callrail_v3_endpoint_path(client_api_integration.webhook_api_key, type: 'outbound_post_call'), params:, headers:)
        end.to change { Contact.count }.from(0).to(1)
        expect(Contact.last.firstname).to eq('Joe')
        expect(campaign.contact_campaigns.count).to eq(1)
      end
    end
  end

  describe 'with form submission webhook', vcr: { record: :once } do
    let(:body_original_string) { '{"resource_id":"FRMdcd4509d27ac457f85f337a3aa1b960b","company_id":347661122,"company_resource_id":"COMdcdc6f0d953941e8bebbd8bf22a03662","person_resource_id":"PERafc378245bd8453094bea49df5bc9ae9","lead_status":null,"form_data":{"your_name":"Joe Tester","email_address":"ian+joetester@chiirp.com","phone_number":"714-555-1212","message":"Hello there. Looks good!","address_zip":"98208","address_city":"Everett","phone_number":"714-239-5588","address_addr1":"101 Main St","address_addr2":"","address_state":"Washington","email_address":"ian+neubs@ianneubert.com"},"url":"https://js.callrail.com/forms/FORd3749ff49f37424a9de282c614b9199c/direct","form_url":"https://js.callrail.com/forms/FORd3749ff49f37424a9de282c614b9199c/direct","source":"Radio Ad","keywords":null,"campaign":null,"medium":"direct","landing":null,"landing_page_url":null,"referrer":"Radio Ad","referrer_url":null,"referring_url":null,"timeline_url":"https://app.callrail.com/analytics/a/728790660/events/PERafc378245bd8453094bea49df5bc9ae9?event_id=FRMdcd4509d27ac457f85f337a3aa1b960b\u0026event_type=form_capture","utm_source":"offline","utm_medium":"direct","utm_campaign":"Radio Ad","submitted_at":"2023-01-24T16:18:46.266-05:00","first_form":false,"utma":null,"utmb":null,"utmc":null,"utmv":null,"utmz":null,"ga":null,"session_uuid":null,"created_at":"2023-01-24T16:18:46.290-05:00","updated_at":"2023-01-24T16:18:46.290-05:00","hidden":null,"fcid":null,"timestamp":"2023-01-24T16:18:46.290-05:00","webhook_api_key":"[FILTERED]"}' }

    it 'returns no content' do
      post(integrations_callrail_v3_endpoint_path(client_api_integration.webhook_api_key, type: 'form_submission'), params:, headers:)

      expect(response).to have_http_status(:no_content)
    end

    it 'processes a webhook event' do
      expect do
        post(integrations_callrail_v3_endpoint_path(client_api_integration.webhook_api_key, type: 'form_submission'), params:, headers:)
      end.to change { Contact.count }.from(0).to(1)
      expect(Contact.last.firstname).to eq('Joe')
      expect(Contact.last.address1).to eq('101 Main St')
      expect(campaign.contact_campaigns.count).to eq(1)
    end

    it 'creates a raw post record' do
      expect do
        post(integrations_callrail_v3_endpoint_path(client_api_integration.webhook_api_key, type: 'form_submission'), params:, headers:)
      end.to change { Contacts::RawPost.count }.from(0).to(1)
      Contacts::RawPost.last.tap do |raw_post|
        expect(raw_post.ext_source).to eq 'callrail'
        expect(raw_post.ext_id).to eq 'callcompleted'
        expect(raw_post.data['person_resource_id']).to eq 'PERafc378245bd8453094bea49df5bc9ae9'
      end
    end
  end
end
