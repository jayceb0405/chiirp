class AddEmployeesToClientApiIntegration < ActiveRecord::Migration[7.0]
  def up
    ActiveRecord::Base.record_timestamps = false
    say 'Turned off timestamps.'

    say_with_time 'Adding employees to ClientApiIntegration model...' do
      ClientApiIntegration.where(target: 'housecall').find_each do |cai|
        cai.update(employees: {})
      end
    end

    # Contacts::RawPost.find_each { |rp| rp.update(data: rp.data.except('integrations'))

    ActiveRecord::Base.record_timestamps = true
    say 'Turned on timestamps.'
  end

  def down
    ActiveRecord::Base.record_timestamps = false
    say 'Turned off timestamps.'

    say_with_time 'Removing employees to ClientApiIntegration model...' do
      ClientApiIntegration.where(target: 'housecall').find_each do |cai|
        cai.update(data: cai.data.except('employees'))
      end
    end

    ActiveRecord::Base.record_timestamps = true
    say 'Turned on timestamps.'
  end
end
