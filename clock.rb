# frozen_string_literal: true

# clock.rb
require 'clockwork'
require 'active_support/time' # Allow numeric durations (eg: 1.minutes)
require_relative 'config/boot'
require_relative 'config/environment'

module Clockwork
  configure do |config|
    config[:sleep_timeout] = 1
    config[:tz] = 'America/New_York'
    config[:max_threads] = 15
    config[:thread] = false
  end

  handler do |job|
    logger.debug "Running #{job}."
  end

  if Rails.env.development? || Rails.env.staging?
    # every(1.minute,   'Update from SalesRabbit Leads')                                                               { Integration::Salesrabbit.delay(priority: DelayedJob.job_priority('salesrabbit_client_contact_updates'), process: 'salesrabbit_client_contact_updates', queue: DelayedJob.job_queue('salesrabbit_client_contact_updates')).client_contact_updates unless DelayedJob.find_by(process: 'salesrabbit_client_contact_updates', attempts: (0..2)) }

    every(30.minutes, 'Notify Users of Tasks Past Due',                at: ['**:10', '**:40'], skip_first_run: true)  { Task.delay(priority: DelayedJob.job_priority('send_task_notifications'), process: 'send_task_notifications', queue: DelayedJob.job_queue('send_task_notifications')).send_notifications_on_past_due }
    every(30.minutes, 'Notify Users of Tasks Past Deadline',           at: ['**:20', '**:50'], skip_first_run: true)  { Task.delay(priority: DelayedJob.job_priority('send_task_notifications'), process: 'send_task_notifications', queue: DelayedJob.job_queue('send_task_notifications')).send_notifications_on_past_deadline }

    every(1.hour,     'Update status of Messages')                                                                    { Messages::Message.delay(priority: DelayedJob.job_priority('message_status_update'), process: 'message_status_update', queue: DelayedJob.job_queue('message_status_update')).update_all_message_status(past_days: 0, past_hours: 2) }

    every(1.day,      'Update status of Messages',                     at:  '4:00', tz: 'UTC')                        { Messages::Message.delay(priority: DelayedJob.job_priority('message_status_update'), process: 'message_status_update', queue: DelayedJob.job_queue('message_status_update')).update_all_message_status(past_days: 30) }
    every(1.day,      'Charge 10DLC Fees',                             at:  '8:00', tz: 'UTC')                        { Clients::Dlc10::ChargeForCampaignsJob.perform_later }
    # every(1.day,      'Update Housecall Pro Invoices',                 at:  '8:45', tz: 'UTC')                        { Integration::Housecallpro.update_invoice }
    every(1.day,      'Charge Monthly Fees',                           at:  '9:00', tz: 'UTC')                        { Client.delay(priority: DelayedJob.job_priority('charge_monthly_fees'), process: 'charge_monthly_fees', queue: DelayedJob.job_queue('charge_monthly_fees')).charge_monthly_accounts }
    every(1.day,      'Update Mortgage Interest Rates',                at: '10:00', tz: 'UTC')                        { ClientApiIntegration.update_mortgage_interest_rates }
    # every(1.day,      'Load Google Reviews',                           at: '10:00', tz: 'UTC')                        { Integration::Google.load_all_reviews }
    # every(1.day,      'Load PC Richard Current Models',                at:  '6:00', tz: 'Eastern Time (US & Canada)') { Integration::Pcrichard::V1::Base.new(nil).update_custom_fields_with_current_models_for_all_clients }

    every(7.days,     'Purge unattached Blobs',                        at: '4:00', tz: 'UTC')                         { ActiveStorage::Blob.unattached.where(active_storage_blobs: { created_at: ..7.days.ago }).find_each(&:purge) }

    # ServiceTitan Jobs
    # every(1.day,      'Update ServiceTitan Contact Account Balances',  at:  '6:00', tz: 'UTC')                        { Integrations::Servicetitan::V2::Customers::Balance::AllClientsJob.perform_later(do_cgst: true) }
    # every(1.day,      'Update ServiceTitan Job Outstanding Balances',  at:  '6:30', tz: 'UTC')                        { Integrations::Servicetitan::V2::Jobs::Balance::AllClientsJob.perform_later }
    # every(1.day,      'Import ServiceTitan Orphaned Estimates',        at:  '7:00', tz: 'UTC')                        { Integrations::Servicetitan::V2::Estimates::Import::Orphaned::AllClientsJob.perform_later }
    # every(1.hour,     'Update ServiceTitan Open Estimates',            at:  '*:00', tz: 'UTC')                        { Integrations::Servicetitan::V2::Estimates::Open::ExistingAllClientsJob.perform_later }
    # every(1.day,      'Trigger ServiceTitan Membership Events',        at:  '8:00', tz: 'UTC')                        { Integrations::Servicetitan::V2::Memberships::EventsAllClientsJob.perform_later }
    # every(3.hours,    'Update ServiceTitan Open Jobs',                 at:  '*:00', tz: 'UTC')                        { Integrations::Servicetitan::V2::Jobs::Open::ExistingAllClientsJob.perform_later }
    every(1.hour,     'Execute ServiceTitan Reports',                  at: '*:00', tz: 'UTC')                         { Integrations::Servicetitan::V2::Reports::ResultsAllClientsJob.perform_later(report_occurrence: (Time.current.day / 7.0).ceil, report_day: Time.current.strftime('%a'), report_hour: Time.current.strftime('%k').to_i) }
  else
    every(1.minute,   'Update from SalesRabbit Leads')                                                                { Integration::Salesrabbit.delay(priority: DelayedJob.job_priority('salesrabbit_client_contact_updates'), process: 'salesrabbit_client_contact_updates', queue: DelayedJob.job_queue('salesrabbit_client_contact_updates')).client_contact_updates unless DelayedJob.find_by(process: 'salesrabbit_client_contact_updates', attempts: (0..2)) }
    every(1.minute,   'Update AWS Queue Metrics', thread: true)                                                       { QueueMetricsJob.perform_now }

    every(20.minutes, 'Load Google Reviews',                           at: ['**:00', '**:20', '**:40'], tz: 'UTC')    { Integration::Google.load_all_reviews }

    every(30.minutes, 'Notify Users of Tasks Past Due',                at: ['**:10', '**:40'], skip_first_run: true)  { Task.delay(priority: DelayedJob.job_priority('send_task_notifications'), process: 'send_task_notifications', queue: DelayedJob.job_queue('send_task_notifications')).send_notifications_on_past_due }
    every(30.minutes, 'Notify Users of Tasks Past Deadline',           at: ['**:20', '**:50'], skip_first_run: true)  { Task.delay(priority: DelayedJob.job_priority('send_task_notifications'), process: 'send_task_notifications', queue: DelayedJob.job_queue('send_task_notifications')).send_notifications_on_past_deadline }

    every(1.hour,     'Update status of Messages')                                                                    { Messages::Message.delay(priority: DelayedJob.job_priority('message_status_update'), process: 'message_status_update', queue: DelayedJob.job_queue('message_status_update')).update_all_message_status(past_days: 0, past_hours: 2) }

    every(1.day,      'Update status of Messages',                     at:  '4:00', tz: 'UTC')                        { Messages::Message.delay(priority: DelayedJob.job_priority('message_status_update'), process: 'message_status_update', queue: DelayedJob.job_queue('message_status_update')).update_all_message_status(past_days: 30) }
    every(1.day,      'Charge 10DLC Fees',                             at:  '8:00', tz: 'UTC')                        { Clients::Dlc10::ChargeForCampaignsJob.perform_later }
    # every(1.day,      'Update Housecall Pro Invoices',                 at:  '8:45', tz: 'UTC')                        { Integration::Housecallpro.update_invoice }
    every(1.day,      'Charge Monthly Fees',                           at:  '9:00', tz: 'UTC')                        { Client.delay(priority: DelayedJob.job_priority('charge_monthly_fees'), process: 'charge_monthly_fees', queue: DelayedJob.job_queue('charge_monthly_fees')).charge_monthly_accounts }
    every(1.day,      'Update Mortgage Interest Rates',                at: '10:00', tz: 'UTC')                        { ClientApiIntegration.update_mortgage_interest_rates }
    every(1.day,      'Load PC Richard Current Models',                at:  '6:00', tz: 'Eastern Time (US & Canada)') { Integration::Pcrichard::V1::Base.new(nil).update_custom_fields_with_current_models_for_all_clients }
    every(1.day,      'Destroy Expired Packages',                      at:  '3:00', tz: 'Eastern Time (US & Canada)') { Packages::DestroyExpiredPackagesJob.perform_later(process: DelayedJob.job_queue('destroy_expired_packages')) }
    every(1.day,      'Delete Old Sign In Debug Data',                 at:  '5:00', tz: 'UTC')                        { Users::CleanSignInDebugDataJob.perform_later }

    every(7.days,     'Purge unattached Blobs',                        at:  '4:00', tz: 'UTC')                        { ActiveStorage::Blob.unattached.where(active_storage_blobs: { created_at: ..7.days.ago }).find_each(&:purge) }

    # ServiceTitan Jobs
    every(1.day,      'Update ServiceTitan Contact Account Balances',  at:  '6:00', tz: 'UTC')                        { Integrations::Servicetitan::V2::Customers::Balance::AllClientsJob.perform_later(do_cgst: true) }
    every(1.day,      'Update ServiceTitan Job Outstanding Balances',  at:  '6:30', tz: 'UTC')                        { Integrations::Servicetitan::V2::Jobs::Balance::AllClientsJob.perform_later }
    every(1.day,      'Import ServiceTitan Orphaned Estimates',        at:  '7:00', tz: 'UTC')                        { Integrations::Servicetitan::V2::Estimates::Import::Orphaned::AllClientsJob.perform_later }
    every(1.hour,     'Update ServiceTitan Open Estimates',            at:  '*:00', tz: 'UTC')                        { Integrations::Servicetitan::V2::Estimates::Open::ExistingAllClientsJob.perform_later }
    every(1.day,      'Trigger ServiceTitan Membership Events',        at:  '8:00', tz: 'UTC')                        { Integrations::Servicetitan::V2::Memberships::EventsAllClientsJob.perform_later }
    every(1.hour,     'Update ServiceTitan Open Jobs',                 at:  '*:00', tz: 'UTC')                        { Integrations::Servicetitan::V2::Jobs::Open::ExistingAllClientsJob.perform_later }
    every(1.hour,     'Execute ServiceTitan Reports',                  at:  '*:00', tz: 'UTC')                        { Integrations::Servicetitan::V2::Reports::ResultsAllClientsJob.perform_later(report_occurrence: (Time.current.day / 7.0).ceil, report_day: Time.current.strftime('%a'), report_hour: Time.current.strftime('%k').to_i) }
  end

  if Rails.env.production? || Rails.env.staging?
    every(1.hour,       'Revoke expired oauth access tokens', at: '**:05', tz: 'UTC') { Oauth::CleanOldAccessTokensJob.perform_later }
    every(1.day,        'Delete old oauth access tokens',     at: '6:00',  tz: 'UTC') { Oauth::RevokeExpiredAccessTokensJob.perform_later }
  end
end
