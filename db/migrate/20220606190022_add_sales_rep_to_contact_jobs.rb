class AddSalesRepToContactJobs < ActiveRecord::Migration[7.0]
  def up
    ActiveRecord::Base.record_timestamps = false
    say 'Turned off timestamps.'

    say_with_time 'Adding ext_sales_rep_id column to ContactEstimates...' do
      rename_column :contact_estimates, :technician_id, :ext_tech_id
      add_column :contact_estimates, :ext_sales_rep_id, :string, null: false, default: ''
    end

    say_with_time 'Adding ext_sales_rep_id column to ContactJobs...' do
      rename_column :contact_jobs, :technician_id, :ext_tech_id
      add_column :contact_jobs, :ext_sales_rep_id, :string, null: false, default: ''
    end

    say_with_time 'Renaming technician_id column in FcpInvoices...' do
      rename_column :fcp_invoices, :technician_id, :ext_tech_id
    end

    say_with_time 'Renaming technician_id field in ContactApiIntegrations...' do

      ContactApiIntegration.where(target: %w[housecallpro servicetitan]).find_each do |contact_api_integration|
        contact_api_integration.data['ext_tech_id']    = contact_api_integration.data.dig('technician_id').to_s
        contact_api_integration.data['ext_tech_name']  = contact_api_integration.data.dig('technician_name').to_s
        contact_api_integration.data['ext_tech_phone'] = contact_api_integration.data.dig('technician_phone').to_s
        contact_api_integration.data.delete('technician_id')
        contact_api_integration.data.delete('technician_name')
        contact_api_integration.data.delete('technician_phone')
        contact_api_integration.save
      end
    end

    ActiveRecord::Base.record_timestamps = true
    say 'Turned on timestamps.'
  end

  def down
    ActiveRecord::Base.record_timestamps = false
    say 'Turned off timestamps.'

    say_with_time 'Removing ext_sales_rep_id column from ContactEstimates...' do
      rename_column :contact_estimates, :ext_tech_id, :technician_id
      remove_column :contact_estimates, :ext_sales_rep_id
    end

    say_with_time 'Removing ext_sales_rep_id column from ContactJobs...' do
      rename_column :contact_jobs, :ext_tech_id, :technician_id
      remove_column :contact_jobs, :ext_sales_rep_id
    end

    say_with_time 'Renaming ext_tech_id column in FcpInvoices...' do
      rename_column :fcp_invoices, :ext_tech_id, :technician_id
    end

    say_with_time 'Renaming ext_tech_id field in ContactApiIntegrations...' do

      ContactApiIntegration.where(target: %w[housecallpro servicetitan]).find_each do |contact_api_integration|
        contact_api_integration.data['technician_id']    = contact_api_integration.data.dig('ext_tech_id').to_s
        contact_api_integration.data['technician_name']  = contact_api_integration.data.dig('ext_tech_name').to_s
        contact_api_integration.data['technician_phone'] = contact_api_integration.data.dig('ext_tech_phone').to_s
        contact_api_integration.data.delete('ext_tech_id')
        contact_api_integration.data.delete('ext_tech_name')
        contact_api_integration.data.delete('ext_tech_phone')
        contact_api_integration.save
      end
    end

    ActiveRecord::Base.record_timestamps = true
    say 'Turned on timestamps.'
  end
end
