# frozen_string_literal: true

# spec/models/integration/servicetitan/v2/events_spec.rb
# foreman run bundle exec rspec spec/models/integration/servicetitan/v2/events_spec.rb
require 'rails_helper'

# describe 'Integration::Servicetitan::V2::Events' do
#   let(:client_api_integration) { create :client_api_integration_for_servicetitan }

#   describe 'Events' do
#     event = {
#       status:                            'open',
#       tag_id:                            0,
#       group_id:                          0,
#       stage_id:                          0,
#       job_types:                         [],
#       range_max:                         1000,
#       total_max:                         0,
#       total_min:                         0,
#       call_types:                        [],
#       membership:                        [],
#       new_status:                        %w[
#         in_progress
#         hold
#         canceled
#       ],
#       action_type:                       'job_status_changed',
#       campaign_id:                       0,
#       ext_tech_ids:                      [],
#       call_duration:                     60,
#       customer_type:                     [],
#       tag_ids_exclude:                   [],
#       tag_ids_include:                   [],
#       membership_types:                  [],
#       business_unit_ids:                 [],
#       stop_campaign_ids:                 [],
#       orphaned_estimates:                false,
#       job_cancel_reason_ids:             [
#         1_297_943,
#         1_297_944,
#         1_297_945,
#         20_012_193
#       ],
#       membership_days_prior:             90,
#       assign_contact_to_user:            false,
#       start_date_changes_only:           false,
#       membership_campaign_stop_statuses: []
#     }

#     it 'job_status_changed?(action, job_status, job_cancel_reason_ids, job_status_changed)' do
#       expect(Integrations::Servicetitan::V2::Events::ProcessActionsForEventJob.send(:job_status_changed?, event, 'Canceled', [1_234, 1_297_945], true)).to eq(true)
#     end

#     it 'job_status_changed?(action, job_status, job_cancel_reason_ids, job_status_changed)' do
#       expect(Integration::Servicetitan::V2::Base.new(client_api_integration).send(:job_status_changed?, event, 'Canceled', [1_234, 1_297], true)).to eq(false)
#     end

#     it 'job_status_changed?(action, job_status, job_cancel_reason_ids, job_status_changed)' do
#       expect(Integration::Servicetitan::V2::Base.new(client_api_integration).send(:job_status_changed?, event, 'in_progress', [], true)).to eq(true)
#     end

#     it 'job_status_changed?(action, job_status, job_cancel_reason_ids, job_status_changed)' do
#       expect(Integration::Servicetitan::V2::Base.new(client_api_integration).send(:job_status_changed?, event, 'hold', [], true)).to eq(true)
#     end

#     it 'job_status_changed?(action, job_status, job_cancel_reason_ids, job_status_changed)' do
#       expect(Integration::Servicetitan::V2::Base.new(client_api_integration).send(:job_status_changed?, event, 'in_progress', [], true)).to eq(true)
#     end

#     it 'job_status_changed?(action, job_status, job_cancel_reason_ids, job_status_changed)' do
#       expect(Integration::Servicetitan::V2::Base.new(client_api_integration).send(:job_status_changed?, event, 'Canceled', [1_234, 1_297], false)).to eq(false)
#     end

#     it 'job_status_changed?(action, job_status, job_cancel_reason_ids, job_status_changed)' do
#       expect(Integration::Servicetitan::V2::Base.new(client_api_integration).send(:job_status_changed?, event, 'in_progress', [], false)).to eq(false)
#     end
#   end

#   describe 'Events' do
#     event = {
#       status:                            'open',
#       tag_id:                            0,
#       group_id:                          0,
#       stage_id:                          0,
#       job_types:                         [],
#       range_max:                         1000,
#       total_max:                         0,
#       total_min:                         0,
#       call_types:                        [],
#       membership:                        [],
#       new_status:                        %w[in_progress],
#       action_type:                       'job_status_changed',
#       campaign_id:                       0,
#       ext_tech_ids:                      [],
#       call_duration:                     60,
#       customer_type:                     [],
#       tag_ids_exclude:                   [],
#       tag_ids_include:                   [],
#       membership_types:                  [],
#       business_unit_ids:                 [],
#       stop_campaign_ids:                 [],
#       orphaned_estimates:                false,
#       job_cancel_reason_ids:             [
#         1_297_943,
#         1_297_944,
#         1_297_945,
#         20_012_193
#       ],
#       membership_days_prior:             90,
#       assign_contact_to_user:            false,
#       start_date_changes_only:           false,
#       membership_campaign_stop_statuses: []
#     }

#     it 'job_status_changed?(action, job_status, job_cancel_reason_ids, job_status_changed)' do
#       expect(Integration::Servicetitan::V2::Base.new(client_api_integration).send(:job_status_changed?, event, 'Canceled', [1_234, 1_297_945], true)).to eq(false)
#     end

#     it 'job_status_changed?(action, job_status, job_cancel_reason_ids, job_status_changed)' do
#       expect(Integration::Servicetitan::V2::Base.new(client_api_integration).send(:job_status_changed?, event, 'in_progress', [], true)).to eq(true)
#     end

#     it 'job_status_changed?(action, job_status, job_cancel_reason_ids, job_status_changed)' do
#       expect(Integration::Servicetitan::V2::Base.new(client_api_integration).send(:job_status_changed?, event, 'hold', [], true)).to eq(false)
#     end

#     it 'job_status_changed?(action, job_status, job_cancel_reason_ids, job_status_changed)' do
#       expect(Integration::Servicetitan::V2::Base.new(client_api_integration).send(:job_status_changed?, event, 'in_progress', [], false)).to eq(false)
#     end
#   end
#   describe 'Events' do
#     event = {
#       status:                            'open',
#       tag_id:                            0,
#       group_id:                          0,
#       stage_id:                          0,
#       job_types:                         [],
#       range_max:                         1000,
#       total_max:                         0,
#       total_min:                         0,
#       call_types:                        [],
#       membership:                        [],
#       new_status:                        %w[in_progress],
#       action_type:                       'job_rescheduled',
#       campaign_id:                       0,
#       ext_tech_ids:                      [],
#       call_duration:                     60,
#       customer_type:                     [],
#       tag_ids_exclude:                   [],
#       tag_ids_include:                   [],
#       membership_types:                  [],
#       business_unit_ids:                 [],
#       stop_campaign_ids:                 [],
#       orphaned_estimates:                false,
#       job_cancel_reason_ids:             [
#         1_297_943,
#         1_297_944,
#         1_297_945,
#         20_012_193
#       ],
#       membership_days_prior:             90,
#       assign_contact_to_user:            false,
#       start_date_changes_only:           false,
#       membership_campaign_stop_statuses: []
#     }

#     it 'job_status_changed?(action, job_status, job_cancel_reason_ids, job_status_changed)' do
#       expect(Integration::Servicetitan::V2::Base.new(client_api_integration).send(:job_status_changed?, event, 'Canceled', [1_234, 1_297_945], true)).to eq(true)
#     end

#     it 'job_status_changed?(action, job_status, job_cancel_reason_ids, job_status_changed)' do
#       expect(Integration::Servicetitan::V2::Base.new(client_api_integration).send(:job_status_changed?, event, 'in_progress', [], true)).to eq(true)
#     end

#     it 'job_status_changed?(action, job_status, job_cancel_reason_ids, job_status_changed)' do
#       expect(Integration::Servicetitan::V2::Base.new(client_api_integration).send(:job_status_changed?, event, 'hold', [], true)).to eq(true)
#     end

#     it 'job_status_changed?(action, job_status, job_cancel_reason_ids, job_status_changed)' do
#       expect(Integration::Servicetitan::V2::Base.new(client_api_integration).send(:job_status_changed?, event, 'in_progress', [], false)).to eq(true)
#     end
#   end

#   describe 'Events' do
#     event = {
#       status:                            'open',
#       tag_id:                            0,
#       group_id:                          0,
#       stage_id:                          0,
#       job_types:                         [],
#       range_max:                         1000,
#       total_max:                         0,
#       total_min:                         0,
#       call_types:                        [
#         'Unbooked'
#       ],
#       membership:                        [],
#       new_status:                        [],
#       action_type:                       'call_completed',
#       campaign_id:                       0,
#       ext_tech_ids:                      [],
#       call_duration:                     60,
#       customer_type:                     [],
#       call_reason_ids:                   [
#         1_297_954,
#         1_297_956,
#         1_297_957
#       ],
#       tag_ids_exclude:                   [],
#       tag_ids_include:                   [],
#       membership_types:                  [],
#       business_unit_ids:                 [],
#       stop_campaign_ids:                 [],
#       orphaned_estimates:                false,
#       job_cancel_reason_ids:             [],
#       membership_days_prior:             90,
#       assign_contact_to_user:            false,
#       start_date_changes_only:           false,
#       membership_campaign_stop_statuses: []
#     }

#     it 'call_reason_id_matches?(action, call_reason_ids)' do
#       expect(Integration::Servicetitan::V2::Base.new(client_api_integration).send(:call_reason_id_matches?, event, 1_297_956)).to eq(true)
#     end

#     it 'call_reason_id_matches?(action, call_reason_ids)' do
#       expect(Integration::Servicetitan::V2::Base.new(client_api_integration).send(:call_reason_id_matches?, event, 97_956)).to eq(false)
#     end
#   end

#   describe 'Events' do
#     event = {
#       status:                            'open',
#       tag_id:                            0,
#       group_id:                          0,
#       stage_id:                          0,
#       job_types:                         [],
#       range_max:                         1000,
#       total_max:                         0,
#       total_min:                         0,
#       call_types:                        [
#         'Unbooked'
#       ],
#       membership:                        [],
#       new_status:                        [],
#       action_type:                       'call_completed',
#       campaign_id:                       0,
#       ext_tech_ids:                      [],
#       call_duration:                     60,
#       customer_type:                     [],
#       call_reason_ids:                   [],
#       tag_ids_exclude:                   [],
#       tag_ids_include:                   [],
#       membership_types:                  [],
#       business_unit_ids:                 [],
#       stop_campaign_ids:                 [],
#       orphaned_estimates:                false,
#       job_cancel_reason_ids:             [],
#       membership_days_prior:             90,
#       assign_contact_to_user:            false,
#       start_date_changes_only:           false,
#       membership_campaign_stop_statuses: []
#     }

#     it 'call_reason_id_matches?(action, call_reason_ids)' do
#       expect(Integration::Servicetitan::V2::Base.new(client_api_integration).send(:call_reason_id_matches?, event, 1_297_956)).to eq(true)
#     end

#     it 'call_reason_id_matches?(action, call_reason_ids)' do
#       expect(Integration::Servicetitan::V2::Base.new(client_api_integration).send(:call_reason_id_matches?, event, 97_956)).to eq(true)
#     end
#   end

#   describe 'Events' do
#     event = {
#       status:                            'open',
#       tag_id:                            0,
#       group_id:                          0,
#       stage_id:                          0,
#       job_types:                         [],
#       range_max:                         1000,
#       total_max:                         0,
#       total_min:                         0,
#       call_types:                        [
#         'Unbooked'
#       ],
#       membership:                        [],
#       new_status:                        [],
#       action_type:                       'job_scheduled',
#       campaign_id:                       0,
#       ext_tech_ids:                      [],
#       call_duration:                     60,
#       customer_type:                     [],
#       call_reason_ids:                   [
#         1_297_954,
#         1_297_956,
#         1_297_957
#       ],
#       tag_ids_exclude:                   [],
#       tag_ids_include:                   [],
#       membership_types:                  [],
#       business_unit_ids:                 [],
#       stop_campaign_ids:                 [],
#       orphaned_estimates:                false,
#       job_cancel_reason_ids:             [],
#       membership_days_prior:             90,
#       assign_contact_to_user:            false,
#       start_date_changes_only:           false,
#       membership_campaign_stop_statuses: []
#     }

#     it 'call_reason_id_matches?(action, call_reason_ids)' do
#       expect(Integration::Servicetitan::V2::Base.new(client_api_integration).send(:call_reason_id_matches?, event, 1_297_956)).to eq(true)
#     end

#     it 'call_reason_id_matches?(action, call_reason_ids)' do
#       expect(Integration::Servicetitan::V2::Base.new(client_api_integration).send(:call_reason_id_matches?, event, 97_956)).to eq(true)
#     end
#   end
# end
