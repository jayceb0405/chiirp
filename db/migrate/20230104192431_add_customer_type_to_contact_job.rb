class AddCustomerTypeToContactJob < ActiveRecord::Migration[7.0]
  def up
    ActiveRecord::Base.record_timestamps = false
    say 'Turned off timestamps.'

    say_with_time 'Modifying Contacts::Job table...' do
      add_column :contact_jobs, :customer_type, :string
    end

    say_with_time 'Modifying Contacts::Estimate table...' do
      add_column :contact_estimates, :customer_type, :string
    end

    # Process after migration
    #   ActiveRecord::Base.record_timestamps = false
    #   ClientApiIntegration.where(target: 'servicetitan').find_each do |client_api_integration|
    #     client_api_integration.data['custom_field_assignments'] = Hash[client_api_integration.data.dig('custom_field_assignments')&.map { |k, v| [k, v.to_i] } || []]
    #     client_api_integration.save
    #   end
    #   ContactApiIntegration.where(target: 'servicetitan').find_each do |contact_api_integration|
    #     contact_api_integration.data['history_item_ids'] = contact_api_integration.data.dig('historyItemId') || {}
    #     contact_api_integration.data.delete('historyItemId')
    #     contact_api_integration.save
    #   end

    ActiveRecord::Base.record_timestamps = true
    say 'Turned on timestamps.'
  end

  def down
    ActiveRecord::Base.record_timestamps = false
    say 'Turned off timestamps.'

    say_with_time 'Modifying Contacts::Job table...' do
      remove_column :contact_jobs, :customer_type
    end

    say_with_time 'Modifying Contacts::Estimate table...' do
      remove_column :contact_estimates, :customer_type
    end

    # Process after migration
    #   ActiveRecord::Base.record_timestamps = false
    #   ClientApiIntegration.where(target: 'servicetitan').find_each do |client_api_integration|
    #     client_api_integration.data['custom_field_assignments'] = Hash[client_api_integration.data.dig('custom_field_assignments')&.map { |k, v| [k, v.to_s] } || []]
    #     client_api_integration.save
    #   end
    #   ContactApiIntegration.where(target: 'servicetitan').find_each do |contact_api_integration|
    #     contact_api_integration.data['historyItemId'] = contact_api_integration.data.dig('history_item_ids') || {}
    #     contact_api_integration.data.delete('history_item_ids')
    #     contact_api_integration.save
    #   end

    ActiveRecord::Base.record_timestamps = true
    say 'Turned on timestamps.'
  end
end
