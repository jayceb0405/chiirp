class JobNimbusStatuses < ActiveRecord::Migration[7.2]
  def change
    say 'Timestamps NOT turned off.'

    say_with_time 'Migrating sales reps & task types in ClientApiIntegration table...' do

      ClientApiIntegration.where(target: 'jobnimbus', name: '').where.not(api_key: '').each do |client_api_integration|
        jn_model = Integration::Jobnimbus::V1::Base.new(client_api_integration)

        client_api_integration.data.dig('ext_sales_reps')&.each do |ext_sales_rep|
          jn_model.sales_rep_update(id: ext_sales_rep['id'], name: ext_sales_rep['name'], email: ext_sales_rep['email'])
        end

        client_api_integration.data.dig('task_types')&.each do |task_type|
          jn_model.task_type_update(type: task_type)
        end
      end
    end
  end
end
