# frozen_string_literal: true

# app/controllers/integrations/fieldroutes/v1/import_contacts_controller.rb
module Integrations
  module Fieldroutes
    module V1
      class ImportContactsController < Fieldroutes::V1::IntegrationsController
        # (GET) show import contacts screen
        # /integrations/fieldroutes/v1/import_contacts
        # integrations_fieldroutes_v1_import_contacts_path
        # integrations_fieldroutes_v1_import_contacts_url
        def show; end

        # (PUT/PATCH) import Contacts from FieldRoutes
        # /integrations/fieldroutes/v1/import_contacts
        # integrations_fieldroutes_v1_import_contacts_path
        # integrations_fieldroutes_v1_import_contacts_url
        def update
          sanitized_params = import_params

          Integrations::Fieldroutes::V1::Imports::ContactsJob.perform_later(
            actions:   sanitized_params[:actions],
            client_id: current_user.client_id,
            filter:    sanitized_params[:filter],
            user_id:   current_user.id
          )
        end

        private

        def import_params
          sanitized_filters = params.require(:filter).permit(:active_only, :created_period, :updated_period, office_ids: [])
          sanitized_actions = params.require(:actions).permit(above_0: [:campaign_id, :group_id, :import, :stage_id, :tag_id, { stop_campaign_ids: [] }], below_0: [:import, :campaign_id, :group_id, :tag_id, :stage_id, { stop_campaign_ids: [] }], eq_0: [:import, :campaign_id, :group_id, :tag_id, :stage_id, { stop_campaign_ids: [] }])

          created_period = sanitized_filters.dig(:created_period).to_s.split(' to ')
          created_at     = {
            after:  Chronic.parse(created_period.first)&.beginning_of_day,
            before: Chronic.parse(created_period.last)&.end_of_day
          }
          created_at[:after]  = created_at[:after] - 1.second if created_at[:after].present?
          created_at[:before] = created_at[:before] + 1.second if created_at[:before].present?

          updated_period = sanitized_filters.dig(:updated_period).to_s.split(' to ')
          updated_at     = {
            after:  Chronic.parse(updated_period.first)&.beginning_of_day,
            before: Chronic.parse(updated_period.last)&.end_of_day
          }
          updated_at[:after]  = updated_at[:after] - 1.second if updated_at[:after].present?
          updated_at[:before] = updated_at[:before] + 1.second if updated_at[:before].present?

          response = {
            filter:  {
              active_only: sanitized_filters[:active_only].to_bool,
              created_at:,
              # office_ids:  sanitized_filters[:office_ids].compact_blank,
              updated_at:
            },
            actions: {
              below_0: {
                campaign_id:       sanitized_actions[:below_0][:campaign_id].to_i,
                group_id:          sanitized_actions[:below_0][:group_id].to_i,
                import:            sanitized_actions[:below_0][:import].to_bool,
                stage_id:          sanitized_actions[:below_0][:stage_id].to_i,
                tag_id:            sanitized_actions[:below_0][:tag_id].to_i,
                stop_campaign_ids: sanitized_actions[:below_0][:stop_campaign_ids].compact_blank.map(&:to_i)
              },
              above_0: {
                campaign_id:       sanitized_actions[:above_0][:campaign_id].to_i,
                group_id:          sanitized_actions[:above_0][:group_id].to_i,
                import:            sanitized_actions[:above_0][:import].to_bool,
                stage_id:          sanitized_actions[:above_0][:stage_id].to_i,
                tag_id:            sanitized_actions[:above_0][:tag_id].to_i,
                stop_campaign_ids: sanitized_actions[:above_0][:stop_campaign_ids].compact_blank.map(&:to_i)
              },
              eq_0:    {
                campaign_id:       sanitized_actions[:eq_0][:campaign_id].to_i,
                group_id:          sanitized_actions[:eq_0][:group_id].to_i,
                import:            sanitized_actions[:eq_0][:import].to_bool,
                stage_id:          sanitized_actions[:eq_0][:stage_id].to_i,
                tag_id:            sanitized_actions[:eq_0][:tag_id].to_i,
                stop_campaign_ids: sanitized_actions[:eq_0][:stop_campaign_ids].compact_blank.map(&:to_i)
              }
            }
          }

          response[:actions][:eq_0][:stop_campaign_ids]    = [0] if response[:actions][:eq_0][:stop_campaign_ids]&.include?(0)
          response[:actions][:below_0][:stop_campaign_ids] = [0] if response[:actions][:below_0][:stop_campaign_ids]&.include?(0)
          response[:actions][:above_0][:stop_campaign_ids] = [0] if response[:actions][:above_0][:stop_campaign_ids]&.include?(0)

          response
        end
        # example Parameters
        # {
        #   authenticity_token: '[FILTERED]',
        #   filter:             {
        #     office_ids:     ['', '2', '5'],
        #     active_only:    'true',
        #     created_period: '07/02/2024 to 07/27/2024',
        #     updated_period: '07/15/2024 to 07/20/2024'
        #   },
        #   button:             '',
        #   actions:            {
        #     eq_0:    { import: 'true', campaign_id: '', group_id: '', stage_id: '', stop_campaign_ids: [''], tag_id: '' },
        #     below_0: { import: 'true', campaign_id: '', group_id: '', stage_id: '', stop_campaign_ids: [''], tag_id: '' },
        #     above_0: { import: 'true', campaign_id: '', group_id: '', stage_id: '', stop_campaign_ids: [''], tag_id: '' }
        #   },
        #   commit:             'Import & Process Actions'
        # }
      end
    end
  end
end
