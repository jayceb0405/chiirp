class MoveUpdateInvoiceWindowDaysToUpdateBalanceActions < ActiveRecord::Migration[6.1]
  def up
    ActiveRecord::Base.record_timestamps = false
    say 'Turned off timestamps.'

    say_with_time 'Moving update_invoice_window_days from job_complete_actions to update_balance_actions in ClientApiIntegration...' do
      ClientApiIntegration.where(target: 'servicetitan').find_each do |client_api_integration|
        client_api_integration.data['update_balance_actions']['update_invoice_window_days'] = client_api_integration.data['job_complete_actions']['update_invoice_window_days']
        client_api_integration.data['job_complete_actions'].delete('update_invoice_window_days')

        client_api_integration.data['job_complete_actions']['actions'] = client_api_integration.data['job_complete_actions']['estimates'] || {}
        client_api_integration.data['job_complete_actions'].delete('estimates')

        client_api_integration.data['job_complete_actions']['actions'].each do |_id, action|
          action['action_type']   = 'estimate'
          action['customer_type'] = [action['customer_type']]
          action['job_types']     = []
          action['membership']    = [action['has_active_membership'].to_bool ? 'active' : 'inactive']
          action.delete('has_active_membership')
        end

        client_api_integration.data['job_classifications'].each do |job_type_id, campaign_ids|

          if campaign_ids['job_complete_campaign_id'].to_i.positive? || campaign_ids['tech_dispatch_campaign_id'].to_i.positive?
            id = rand(1..10000) while client_api_integration.data['job_complete_actions'].keys.map(&:to_i).include?(id) || id.nil?
            client_api_integration.data['job_complete_actions']['actions'][id] = {
              'status'    => '',
              'tag_id'    => 0,
              'group_id'  => 0,
              'stage_id'  => 0,
              'job_types' => [job_type_id],
              'range_max' => 1000,
              'total_max' => 0,
              'membership' => ['active', 'inactive'],
              'action_type' => campaign_ids['job_complete_campaign_id'].to_i.positive? ? 'job_complete' : 'technician_dispatched',
              'campaign_id' => campaign_ids['job_complete_campaign_id'].to_i.positive? ? campaign_ids['job_complete_campaign_id'].to_i : campaign_ids['tech_dispatch_campaign_id'].to_i,
              'customer_type' => ['commercial', 'residential'],
              'business_unit_ids' => []
            }
          end

          campaign_ids.delete('job_complete_campaign_id')
          campaign_ids.delete('tech_dispatch_campaign_id')
        end

        client_api_integration.data['job_actions'] = client_api_integration.data['job_complete_actions']
        client_api_integration.data.delete('job_complete_actions')

        client_api_integration.save
      end
    end

    ActiveRecord::Base.record_timestamps = true
    say 'Turned on timestamps.'
  end

  def down
    ActiveRecord::Base.record_timestamps = false
    say 'Turned off timestamps.'

    say_with_time 'Moving update_invoice_window_days from update_balance_actions to job_complete_actions in ClientApiIntegration...' do
      ClientApiIntegration.where(target: 'servicetitan').find_each do |client_api_integration|
        client_api_integration.data['job_actions']['update_invoice_window_days'] = client_api_integration.data['update_balance_actions']['update_invoice_window_days']
        client_api_integration.data['update_balance_actions'].delete('update_invoice_window_days')

        client_api_integration.data['job_actions']['estimates'] = client_api_integration.data['job_actions']['actions']
        client_api_integration.data['job_actions'].delete('actions')
        
        client_api_integration.data['job_actions']['estimates'].each do |_id, action|
          action['has_active_membership'] = action['membership'][0].to_s == 'active'
          action['customer_type']         = action['customer_type'][0]

          if action['action_type'] == 'job_complete' && action['job_types'].present? && action['campaign_id'].to_i.positive?
            client_api_integration.data['job_classifications'][action['job_types'][0]]['job_complete_campaign_id'] = action['campaign_id'].to_i
          end

          if action['action_type'] == 'technician_dispatched' && action['job_types'].present? && action['campaign_id'].to_i.positive?
            client_api_integration.data['job_classifications'][action['job_types'][0]]['tech_dispatch_campaign_id'] = action['campaign_id'].to_i
          end

          action.delete('action_type')
          action.delete('job_types')
          action.delete('membership')
        end

        client_api_integration.data['job_classifications'].each do |job_type_id, campaign_ids|
          campaign_ids['job_complete_campaign_id'] = 0 unless campaign_ids['job_complete_campaign_id'].to_i.positive?
          campaign_ids['tech_dispatch_campaign_id'] = 0 unless campaign_ids['tech_dispatch_campaign_id'].to_i.positive?
        end

        client_api_integration.data['job_complete_actions'] = client_api_integration.data['job_actions']
        client_api_integration.data.delete('job_actions')

        client_api_integration.save
      end
    end

    ActiveRecord::Base.record_timestamps = true
    say 'Turned on timestamps.'
  end
end
