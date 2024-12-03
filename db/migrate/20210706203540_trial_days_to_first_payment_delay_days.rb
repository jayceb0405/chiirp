class TrialDaysToFirstPaymentDelayDays < ActiveRecord::Migration[6.1]
  def up
    ActiveRecord::Base.record_timestamps = false
    say 'Turned off timestamps.'

    say_with_time 'Updating trial_days to first_payment_delay_days in Client model...' do
      Client.find_each do |client|
        client.data['first_payment_delay_days']   = client.data['trial_days']
        client.data['first_payment_delay_months'] = 0
        client.data['promo_months']               = 0
        client.data['promo_mo_charge']            = 0.0
        client.data['promo_credit_charge']        = 0.0
        client.data['promo_mo_credits']           = 0.0
        client.data['promo_max_phone_numbers']    = 0
        client.data.delete('trial_days')
        client.save
      end
    end

    say_with_time 'Updating trial_days to first_payment_delay_days in Package model...' do
      Package.find_each do |package|
        package.package_data['first_payment_delay_days']   = package.package_data['trial_days']
        package.package_data['first_payment_delay_months'] = 0
        package.package_data['promo_months']               = 0
        package.package_data['promo_mo_charge']            = 0.0
        package.package_data['promo_credit_charge']        = 0.0
        package.package_data['promo_mo_credits']           = 0.0
        package.package_data['promo_max_phone_numbers']    = 0
        package.package_data.delete('trial_days')
        package.save
      end
    end

    ActiveRecord::Base.record_timestamps = true
    say 'Turned on timestamps.'
  end

  def down
    ActiveRecord::Base.record_timestamps = false
    say 'Turned off timestamps.'

    say_with_time 'Reverting first_payment_delay_days to trial_days in Client model...' do
      Client.find_each do |client|
        client.data['trial_days'] = client.data['first_payment_delay_days']
        client.data.delete('first_payment_delay_days')
        client.data.delete('first_payment_delay_months')
        client.data.delete('promo_months')
        client.data.delete('promo_mo_charge')
        client.data.delete('promo_credit_charge')
        client.data.delete('promo_mo_credits')
        client.data.delete('promo_max_phone_numbers')
        client.save
      end
    end

    say_with_time 'Reverting first_payment_delay_days to trial_days in Package model...' do
      Package.find_each do |package|
        package.package_data['trial_days'] = package.package_data['first_payment_delay_days']
        package.package_data.delete('first_payment_delay_days')
        package.package_data.delete('first_payment_delay_months')
        package.package_data.delete('promo_months')
        package.package_data.delete('promo_mo_charge')
        package.package_data.delete('promo_credit_charge')
        package.package_data.delete('promo_mo_credits')
        package.package_data.delete('promo_max_phone_numbers')
        package.save
      end
    end

    ActiveRecord::Base.record_timestamps = true
    say 'Turned on timestamps.'
  end
end
