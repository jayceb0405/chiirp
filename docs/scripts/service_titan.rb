# frozen_string_literal: true

# Find servicetitan integrations that have business units
# This was used to find integrations to test with AI Agents.
valid_cais = []
ClientApiIntegration.where(target: 'servicetitan', name: '').find_each do |cai|
  st_model = Integration::Servicetitan::V2::Base.new(cai)
  st_client = Integrations::ServiceTitan::Base.new(cai.credentials)
  if st_model.valid_credentials?
    st_client.business_units
    valid_cais << cai if st_client.success? && st_client.result.any?
  end
end

# of those that have a business unit, find cai's that have a contact with a valid ext_customer_id
valid_cais.reverse.each do |cai|
  st_client = Integrations::ServiceTitan::Base.new(cai.credentials)
  cai.client.contacts.each do |contact|
    next unless (ext_ref = contact.ext_references.find_by(target: 'servicetitan')&.ext_id)
    if st_client.locations(customer_id: ext_ref).any?
      puts "client_id: #{cai.client.id} -> ext_customer_id: #{ext_ref}"
      cai.credentials.each do |name, value|
        puts name
        puts value
        puts
      end
      exit 0
    end
  end
end

# Use this to quickly reset the access keys on a ST client
Aiagent::Session.find(1).send(:st_client)
