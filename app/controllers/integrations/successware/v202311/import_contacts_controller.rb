# frozen_string_literal: true

# app/controllers/integrations/successware/v202311/import_contacts_controller.rb
module Integrations
  module Successware
    module V202311
      class ImportContactsController < Successware::IntegrationsController
        # (GET) show import contacts screen
        # /integrations/successware/v202311/import_contacts
        # integrations_successware_v202311_import_contacts_path
        # integrations_successware_v202311_import_contacts_url
        def show
          render partial: 'integrations/successware/v202311/js/show', locals: { cards: %w[show_import_contacts] }
        end

        # (PUT) import Contacts from Successware
        # /integrations/successware/v202311/import_contacts
        # integrations_successware_v202311_import_contacts_path
        # integrations_successware_v202311_import_contacts_url
        def update
          sanitized_params = import_params

          Integrations::Successware::V202311::ImportContactsJob.perform_later(
            actions: sanitized_params[:actions],
            filter:  sanitized_params[:filter],
            user_id: current_user.id
          )

          render partial: 'integrations/successware/v202311/js/show', locals: { cards: %w[show_import_contacts] }
        end

        def import_params
          sanitized_filters = params.require(:filter).permit(is_company: %i[commercial residential])
          sanitized_actions = params.require(:actions).permit(above_0: [:campaign_id, :group_id, :import, :stage_id, :tag_id, { stop_campaign_ids: [] }], below_0: [:import, :campaign_id, :group_id, :tag_id, :stage_id, { stop_campaign_ids: [] }], eq_0: [:import, :campaign_id, :group_id, :tag_id, :stage_id, { stop_campaign_ids: [] }])

          response = {
            filter:  {
              commercial:  sanitized_filters[:is_company][:commercial].to_bool,
              residential: sanitized_filters[:is_company][:residential].to_bool
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
        #     "is_company"=>{"commercial"=>"true", "residential"=>"true"}
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
