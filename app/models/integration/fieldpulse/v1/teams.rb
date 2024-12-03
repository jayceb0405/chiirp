# frozen_string_literal: true

# app/models/Integration/fieldpulse/v1/teams.rb
module Integration
  module Fieldpulse
    module V1
      module Teams
        # call FieldPulse API to update ClientApiIntegration.teams
        # Integration::Fieldpulse::V1::Base.new(client_api_integration).refresh_teams
        def refresh_teams
          return unless valid_credentials?

          client_api_integration_teams.update(data: @fp_client.teams, updated_at: Time.current)
        end

        def teams_last_updated
          client_api_integration_teams_data.present? ? client_api_integration_teams.updated_at : nil
        end

        # return a specific team's data
        # Integration::Fieldpulse::V1::Base.new(client_api_integration).team()
        #   (req) fp_team_id: (Integer)
        #   (opt) raw:        (Boolean / default: false)
        def team(fp_team_id, args = {})
          return [] if fp_team_id.to_i.zero?

          if (team = client_api_integration_teams_data.find { |t| t['id'] == fp_team_id })

            if args.dig(:raw).to_bool
              team.deep_symbolize_keys
            else
              {
                id:         team.dig('id').to_i,
                name:       team.dig('title').to_s,
                about:      team.dig('about').to_s,
                company_id: team.dig('company_id').to_i,
                members:    team.dig('members').map { |member| { id: member['id'].to_i, name: Friendly.new.fullname(member.dig('first_name')&.to_s, member.dig('last_name')&.to_s), phone: member.dig('phone').to_s, email: member.dig('email').to_s } }
              }
            end
          elsif args.dig(:raw).to_bool
            {}
          else
            {
              id:      0,
              name:    '',
              about:   '',
              members: []
            }
          end
        end

        # return all teams data
        # Integration::Fieldpulse::V1::Base.new(client_api_integration).teams()
        #   (opt) for_select:       (Boolean / default: false)
        #   (opt) raw:              (Boolean / default: false)
        def teams(args = {})
          response = client_api_integration_teams_data

          if args.dig(:for_select).to_bool
            response.map { |t| [t.dig('title').to_s, t.dig('id').to_i] }.sort
          elsif args.dig(:raw).to_bool
            response.map(&:deep_symbolize_keys)
          else
            response.map { |t| { id: t.dig('id'), name: t.dig('title').to_s, about: t.dig('about'), company_id: t.dig('company_id').to_i, members: t.dig('members').map { |m| { id: m['id'].to_i, name: Friendly.new.fullname(m.dig('first_name')&.to_s, m.dig('last_name')&.to_s), phone: m.dig('phone').to_s, email: m.dig('email').to_s } } } }&.sort_by { |t| t[:name] }
          end
        end

        private

        def client_api_integration_teams
          @client_api_integration_teams ||= @client.client_api_integrations.find_or_create_by(target: 'fieldpulse', name: 'teams')
        end

        def client_api_integration_teams_data
          refresh_teams if client_api_integration_teams.updated_at < 7.days.ago || client_api_integration_teams.data.blank?

          client_api_integration_teams.data.presence || []
        end
      end
    end
  end
end
