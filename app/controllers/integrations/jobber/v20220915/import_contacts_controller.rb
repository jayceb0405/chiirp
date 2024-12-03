# frozen_string_literal: true

# app/controllers/integrations/jobber/v20220915/import_contacts_controller.rb
module Integrations
  module Jobber
    module V20220915
      class ImportContactsController < Jobber::V20220915::IntegrationsController
        # (GET) show import contacts screen
        # /integrations/jobber/v20220915/import_contacts
        # integrations_jobber_v20220915_import_contacts_path
        # integrations_jobber_v20220915_import_contacts_url
        def show
          render partial: 'integrations/jobber/v20220915/js/show', locals: { cards: %w[show_import_contacts] }
        end

        # (PUT) import Contacts from Jobber
        # /integrations/jobber/v20220915/import_contacts
        # integrations_jobber_v20220915_import_contacts_path
        # integrations_jobber_v20220915_import_contacts_url
        def update
          sanitized_params = import_params

          run_at = Time.current
          data   = {
            actions: sanitized_params[:actions],
            filter:  sanitized_params[:filter],
            user_id: current_user.id
          }
          Integration::Jobber::V20220915::Base.new(@client_api_integration).delay(
            run_at:,
            priority:            DelayedJob.job_priority('jobber_import_contacts'),
            queue:               DelayedJob.job_queue('jobber_import_contacts'),
            user_id:             current_user.id,
            contact_id:          0,
            triggeraction_id:    0,
            contact_campaign_id: 0,
            group_process:       0,
            process:             'jobber_import_contacts',
            data:
          ).import_contacts(data)

          render partial: 'integrations/jobber/v20220915/js/show', locals: { cards: %w[show_import_contacts] }
        end

        def import_params
          sanitized_filters = params.require(:filter).permit(:created_period, :is_archived, :is_lead, :updated_period, tags: [], is_company: %i[commercial residential])
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
              created_at:,
              is_archived: sanitized_filters[:is_archived].to_bool,
              is_company:  sanitized_filters[:is_company][:commercial].to_bool && sanitized_filters[:is_company][:residential].to_bool ? nil : sanitized_filters[:is_company][:commercial].to_bool,
              is_lead:     sanitized_filters[:is_lead].to_bool,
              tags:        Tag.where(client_id: @client_api_integration.client_id, id: sanitized_filters[:tags].map(&:to_i).compact_blank).pluck(:name),
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
        #   "authenticity_token"=>"[FILTERED]",
        #   "filter"=>{
        #     "is_company"=>{"commercial"=>"true", "residential"=>"true"},
        #     "is_lead"=>"false",
        #     "is_archived"=>"false",
        #     "created_period"=>"11/01/2023 to 11/21/2023",
        #     "updated_period"=>"",
        #     "tags"=>[""]
        #   },
        #   "button"=>"",
        #   "actions"=>{
        #     "eq_0"=>{"import"=>"false", "campaign_id"=>"", "group_id"=>"", "tag_id"=>"", "stage_id"=>"", "stop_campaign_ids"=>[""]},
        #     "below_0"=>{"import"=>"false", "campaign_id"=>"", "group_id"=>"", "tag_id"=>"", "stage_id"=>"", "stop_campaign_ids"=>[""]},
        #     "above_0"=>{"import"=>"true", "campaign_id"=>"", "group_id"=>"", "tag_id"=>"", "stage_id"=>"", "stop_campaign_ids"=>[""]}
        #   },
        #   "group"=>{"actions"=>{"eq_0"=>{"group_id"=>{"name"=>""}}, "below_0"=>{"group_id"=>{"name"=>""}}, "above_0"=>{"group_id"=>{"name"=>""}}}}, "tag"=>{"actions"=>{"eq_0"=>{"tag_id"=>{"name"=>""}}, "below_0"=>{"tag_id"=>{"name"=>""}}, "above_0"=>{"tag_id"=>{"name"=>""}}}},
        #   "commit"=>"Import & Process Actions"
        # }
      end
    end
  end
end
