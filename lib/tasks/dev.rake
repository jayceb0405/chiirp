# frozen_string_literal: true

namespace :dev do
  task seed: :environment do
    # setup cardx data
    client = User.find(80).client
    client.update! integrations_allowed: User.last.client.integrations_allowed + ['cardx'] unless User.find(80).client.integrations_allowed.include?('cardx')
    client.client_api_integrations.find_by(target: 'cardx', name: '').update! client_id: User.find(80).client.id, target: 'cardx', account: 'chiirp', webhook_header_token: Rails.application.credentials.dig(:data, :cardx, :webhook_header_token), webhook_api_key: Rails.application.credentials.dig(:data, :cardx, :webhook_api_key)

    # setup email
    client.update! integrations_allowed: User.last.client.integrations_allowed + ['email'] unless User.find(80).client.integrations_allowed.include?('email')
    cai = ClientApiIntegration.find_by(client_id: 1, target: 'email', name: '')
    cai.update! api_key: Rails.application.credentials.dig(:sendgrid, :ian_dev),
                data:    { 'ips'        => ['149.72.26.131'],
                           'dkim1'      => { 'data' => 'vci.domainkey.u44914101.wl102.sendgrid.net', 'host' => 'vci._domainkey.ianster.com', 'valid' => true, 'reason' => nil },
                           'dkim2'      => { 'data' => 'vci2.domainkey.u44914101.wl102.sendgrid.net', 'host' => 'vci2._domainkey.ianster.com', 'valid' => true, 'reason' => nil },
                           'email'      => 'support+sg-chiirp-client-development-1@chiirp.com',
                           'domain'     => 'ianster.com',
                           'password'   => Rails.application.credentials.dig(:sendgrid, :ian_dev_password),
                           'username'   => 'sg-chiirp-client-development-1',
                           'domain_id'  => 20_716_448,
                           'mail_cname' => { 'data' => 'u44914101.wl102.sendgrid.net', 'host' => 'em1813.ianster.com', 'valid' => true, 'reason' => nil } }

    ClientApiIntegration.find_by(client_id: 1, target: 'email').update! inbound_username: '6a4ukmdarrjv5tjkjcnj'

    # remove five9
    client.update! integrations_allowed: client.integrations_allowed.reject { |i| i == 'five9' }

    ccf = ClientCustomField.create!(
      client_id:       1,
      var_name:        'Is The Caller Authorized To Pay For This Work?',
      var_var:         'is_the_caller_authorized_to_pay_for_this_work_',
      var_type:        'string',
      var_placeholder: 'Is The Caller Authorized To Pay For This Work?',
      var_important:   true,
      image_is_valid:  false
    )
    ccf.var_options = { string_options: 'Yes - Authorized to Approve the Work Required,No if not they can not book the job,Property Manager - Authorized to Approve the Work Required Commercial Client - Authorized to Approve the Work Required,Home Warranty Provider - Authorized to Approve the Work Required' }
    ccf.save!

    cai = client.client_api_integrations.find_by(target: 'servicetitan', name: '')
    cai.update booking_fields: {
      '119778' => { 'use' => 'req', 'name' => 'Is The Caller Authorized To Pay For The Work?', 'order' => '0', 'client_custom_field_id' => ccf.id }
    }

    # wayne gretzky
    Contact.find(29_777).ext_references.destroy_all
    Contact.find(29_777).ext_references.create! target: 'servicetitan', ext_id: '72394296'

    # set aiagent template usage
    Client.find(1).update! max_email_templates: -1, aiagent_included_count: -1, share_aiagents_allowed: true, aiagent_trial_period_days: 0, aiagent_trial_period_months: 3

    # remove Kevin's aiagent
    Aiagent.find(1).destroy

    # add an aiagent
    aiagent = Aiagent.create! client_id: 1, name: 'AI Agent Test', initial_prompt: 'Would you like to enter our contest to win a free pool cleaning?', ending_prompt: 'Thank you!', action: 'extract_data', max_messages: 20, max_messages_prompt: 'We will be in touch.', custom_fields: { address1: { order: '0', show: '1', required: '1' }, city: { order: '1', show: '1', required: '1' }, state: { order: '2', show: '1', required: '1' }, zipcode: { order: '3', show: '1', required: '1' } }
    system_prompt = <<~PROMPT
      You are a customer service representative who's goal is to get a client's information.
      After you have collected the information, tell the client that it will take a moment to process their request.
      Do not talk about things outside your goal.
      If the customer is not interested, then call the get_help function.
    PROMPT
    aiagent.update(system_prompt:)
    Aiagent.create! client_id: 1, action: 'quick_response', name: 'Test Responder', system_prompt: 'Your name is John and your goal is to help people with homework.', lookback_days: 3

    # allow ian to use email templates && aiagents && quick responses
    user = User.find(80)
    user.email_templates_controller = ['allowed']
    user.aiagents_controller = ['allowed']
    user.central_controller = %w[allowed all_contacts manage_quick_responses]
    user.super_admin = true
    user.save! validate: false

    # allow ian to use phone number
    Twnumber.find(40).twnumberusers.create! user_id: 80, def_user: false

    # remove kevin's contact for me
    Contact.find(29_816).destroy
    Contact.find(29_817).destroy

    # Add self contact
    contact = user.contacts.create! firstname: 'Ian', lastname: 'Neubert', ok2text: '1', ok2email: '1', companyname: 'Chiirp', address1: '71 N 490 W', city: 'American Fork', state: 'UT', zipcode: '84003'
    contact.email = 'ian@chiirp.com'
    contact.save! validate: false
    contact.contact_phones.create! phone: '7144758933', label: 'mobile', primary: true
    contact.contact_phones.create! phone: '9494846382', label: 'work', primary: false

    # Add custom email section to good job email
    EmailTemplate.find(2).update! content: "#{EmailTemplate.find(2).content}<p>\#{custom_email_section}</p>"

    # Tweak integrations
    SystemSettings::Integration.find(30).update(integration: 'webhooks')
    SystemSettings::Integration.find(29).update(link_url: '/integrations/sunbasedata/integration')

    # remove all existing jobs
    Delayed::Job.destroy_all

    # Remove any db_loaders
    DbLoader.destroy_all

    # Remove any ActionMailbox InboundEmail
    ActionMailbox::InboundEmail.destroy_all

    # Add raw post for contact
    contact.raw_posts.create! ext_source: 'asdf', ext_id: 'q234123', data: { 'test' => 'data' }, created_at: 6.hours.ago
    contact.raw_posts.create! ext_source: 'asdf', ext_id: 'none', data: { 'asdf' => 1 }

    # Add Postman oauth application
    app = Doorkeeper::Application.create! name: 'Postman', redirect_uri: 'https://oauth.pstmn.io/v1/callback', scopes: 'write', confidential: false
    app.update! uid: Rails.application.credentials.doorkeeper&.postman&.uid if Rails.application.credentials.doorkeeper&.postman&.uid
  end

  task domains: :environment do
    domains = ClientApiIntegration.where(target: 'email').map { |cai| cai.data['domain'] }.compact_blank

    dns = Resolv::DNS.new(nameserver: '8.8.8.8')
    out = []

    domains.each do |domain|
      begin
        out << dns.getresource(domain, Resolv::DNS::Resource::IN::TXT)
      rescue StandardError
        nil
      end
    end

    Rails.logger.info out.compact_blank.inspect
  end
end

#################
# DEV
#################
# foreman start web
# foreman start all=1,web=0,clock=0,release=0
# foreman run rails c
# foreman run rails credentials:edit

# git checkout master db/schema.rb ; dc down ;dc up -d; sleep 2; ./bin/reset_db_from_backup

#################
# PRODUCTION
#################
# heroku run --app chiirpapp rails c

#################
# LOGS
#################
# AI Agent responses
# https://my.papertrailapp.com/systems/chiirpapp/events?q=AiAgent.chat
