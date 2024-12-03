# frozen_string_literal: true

# app/models/Integration/salesrabbit.rb
module Integration
  class Salesrabbit < ApplicationRecord
    # get updated leads from SalesRabbit
    # initial process
    # called from clock.rb
    # Integration::Salesrabbit.client_contact_updates
    def self.client_contact_updates
      JsonLog.info 'Integration::Salesrabbit.client_contact_updates'
      ClientApiIntegration.where(target: 'salesrabbit').where.not(api_key: [nil, '']).includes(:client).find_each(batch_size: 100) do |client_api_integration|
        next unless client_api_integration.client.active?

        time_now  = Time.current.utc
        sr_client = Integrations::SalesRabbit::Base.new(client_api_integration.api_key)
        result    = sr_client.leads(start_time: client_api_integration.last_request_time.to_time)

        if sr_client.success? && result.present?
          Integration::Salesrabbit.delay(
            priority: DelayedJob.job_priority('salesrabbit_update_contacts_from_leads'),
            queue:    DelayedJob.job_queue('salesrabbit_update_contacts_from_leads'),
            process:  'salesrabbit_update_contacts_from_leads',
            data:     { client_id: client_api_integration.client_id, leads: result }
          ).update_contacts_from_leads(client_api_integration.client_id, result)
        end

        client_api_integration.update(last_request_time: time_now)
      end
    end

    # remove reference to a Campaign/Group/Stage/Tag that was destroyed
    # Integration::Salesrabbit.references_destroyed()
    #   (req) client_id:      (Integer)
    #   (opt) campaign_id:    (Integer)
    #   (opt) group_id:       (Integer)
    #   (opt) tag_id:         (Integer)
    #   (opt) stage_id:       (Integer)
    def self.references_destroyed(**args)
      return false unless (Integer(args.dig(:client_id), exception: false) || 0).positive? &&
                          (client_api_integration = ClientApiIntegration.find_by(client_id: args[:client_id], target: 'salesrabbit', name: '')) &&
                          ((Integer(args.dig(:campaign_id), exception: false) || 0).positive? || (Integer(args.dig(:group_id), exception: false) || 0).positive? ||
                          (Integer(args.dig(:stage_id), exception: false) || 0).positive? || (Integer(args.dig(:tag_id), exception: false) || 0).positive?)

      campaign_id = args.dig(:campaign_id).to_i
      group_id    = args.dig(:group_id).to_i
      stage_id    = args.dig(:stage_id).to_i
      tag_id      = args.dig(:tag_id).to_i

      client_api_integration.status_actions&.dig('campaigns')&.each do |action, action_campaign_id|
        client_api_integration.status_actions['campaigns'][action] = 0 if action_campaign_id.to_i == campaign_id
      end
      client_api_integration.status_actions&.dig('groups')&.each do |action, action_group_id|
        client_api_integration.status_actions['groups'][action] = 0 if action_group_id.to_i == group_id
      end
      client_api_integration.status_actions&.dig('stages')&.each do |action, action_stage_id|
        client_api_integration.status_actions['stages'][action] = 0 if action_stage_id.to_i == stage_id
      end
      client_api_integration.status_actions&.dig('tags')&.each do |action, action_tag_id|
        client_api_integration.status_actions['tags'][action] = 0 if action_tag_id.to_i == tag_id
      end

      client_api_integration.save
    end

    # update a Contact from a SalesRabbit lead
    # called from Integration::Salesrabbit.update_contacts_from_leads
    # Integration::Salesrabbit.update_contact(integer, Hash)
    def self.update_contact(client_id, lead)
      JsonLog.info('Integration::Salesrabbit.update_contact', { lead: }, client_id:)
      return unless lead.is_a?(Hash) && (client_api_integration = ClientApiIntegration.find_by(client_id:, target: 'salesrabbit', name: ''))

      contact = Contact.find_or_initialize_by_phone_or_email_or_ext_ref(client_id:, phones: { lead.dig(:phonePrimary).to_s => 'mobile' }, emails: [lead.dig(:email)], ext_refs: { 'salesrabbit' => lead.dig(:id).to_i })
      new_contact = contact.new_record?
      contact.update(lastname: lead.dig(:lastName), firstname: lead.dig(:firstName))

      contact_api_integration = contact.contact_api_integrations.find_or_initialize_by(target: 'salesrabbit', name: '')
      status_updated = contact_api_integration.status != lead.dig(:status)
      contact_api_integration.update(status: lead.dig(:status))

      user_id = client_api_integration.users_users.invert[lead.dig(:userId).to_s].to_i
      contact.update(user_id:) if user_id.positive? && client_api_integration.client.users.find_by(id: user_id)

      if new_contact
        JsonLog.info 'Integration::Salesrabbit.update_contact-new_contact'
        campaign_id       = client_api_integration.new_contact_actions.dig('campaign_id').to_i
        group_id          = client_api_integration.new_contact_actions.dig('group_id').to_i
        tag_id            = client_api_integration.new_contact_actions.dig('tag_id').to_i
        stage_id          = client_api_integration.new_contact_actions.dig('stage_id').to_i
        stop_campaign_ids = client_api_integration.new_contact_actions.dig('stop_campaign_ids')
      elsif status_updated
        JsonLog.info 'Integration::Salesrabbit.update_contact-status_changed'
        status_index = client_api_integration.statuses.index { |status| status['name'] == lead.dig(:status) }

        campaign_id       = client_api_integration.status_actions.dig('campaigns', client_api_integration.statuses[status_index]['id']).to_i
        group_id          = client_api_integration.status_actions.dig('groups', client_api_integration.statuses[status_index]['id']).to_i
        tag_id            = client_api_integration.status_actions.dig('tags', client_api_integration.statuses[status_index]['id']).to_i
        stage_id          = client_api_integration.status_actions.dig('stages', client_api_integration.statuses[status_index]['id']).to_i
        stop_campaign_ids = client_api_integration.status_actions.dig('stop_campaign_ids', client_api_integration.statuses[status_index]['id'])
      # SalesRabbit status changed
      else
        JsonLog.info 'Integration::Salesrabbit.update_contact-nothing'
        campaign_id       = 0
        group_id          = 0
        tag_id            = 0
        stage_id          = 0
        stop_campaign_ids = []
      end

      contact.process_actions(
        campaign_id:,
        group_id:,
        stage_id:,
        tag_id:,
        stop_campaign_ids:
      )
    end

    # update Contacts from SalesRabbit leads
    # break down all SalesRabbit leads into each lead
    # called from Integration::Salesrabbit.client_contact_updates
    # Integration::Salesrabbit.update_contacts_from_leads(Integer, Array)
    def self.update_contacts_from_leads(client_id, leads)
      JsonLog.info('Integration::Salesrabbit.update_contacts_from_leads', { leads: }, client_id:)
      return unless leads.is_a?(Array)

      leads.each do |lead|
        Integration::Salesrabbit.delay(
          priority: DelayedJob.job_priority('salesrabbit_update_contact'),
          queue:    DelayedJob.job_queue('salesrabbit_update_contact'),
          process:  'salesrabbit_update_contact',
          data:     { client_id:, lead: }
        ).update_contact(client_id, lead)
      end
    end
  end
end
