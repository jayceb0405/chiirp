# frozen_string_literal: true

# app/lib/integrations/slacker/channels.rb
module Integrations
  module Slacker
    module Channels
      # find a Slack channel by name
      # slack_client.channel(name (String))
      def channel(name)
        reset_attributes
        @result  = self.channels.find { |c| c[:name] == name } || {}
        @success = @result.present?
        @message = "Channel (#{name}) not found" unless @success

        @result
      end

      # call Slack API to create a new channel
      # slack_client.channel_create(name)
      def channel_create(name)
        reset_attributes
        name    = normalize_channel_name(name)
        @result = {}

        if name.blank?
          @message = 'Slack channel required'
          return @result
        end

        body = {
          name:
        }

        slack_request(
          body:,
          error_message_prepend: 'Integrations::Slacker::Base.channel_create',
          method:                'post',
          params:                nil,
          default_result:        {},
          url:                   "#{base_api_url}/conversations.create"
        )

        if @success && @result.is_a?(Hash)
          response = @result.dig(:channel) || {}
        elsif !@success && @result.is_a?(Hash) && @result.dig(:error).to_s.casecmp?('name_taken') && (channel = self.channel(name)).present?
          @success = true
          response = channel
        else
          response = {}
          @success = false
          @message = "Unexpected response: #{@result.inspect}" if @message.blank?
        end

        @result = response
      end
      # response (name_taken) ex:
      # {
      #   ok:    false,
      #   error: "name_taken"
      # }
      # response (channel created) ex:
      # {
      #   ok:      true,
      #   channel: {
      #     id:                         'C06L324S353',
      #     name:                       'chiirp_slacker',
      #     is_channel:                 true,
      #     is_group:                   false,
      #     is_im:                      false,
      #     is_mpim:                    false,
      #     is_private:                 false,
      #     created:                    1708619629,
      #     is_archived:                false,
      #     is_general:                 false,
      #     unlinked:                   0,
      #     name_normalized:            'chiirp_slacker',
      #     is_shared:                  false,
      #     is_org_shared:              false,
      #     is_pending_ext_shared:      false,
      #     pending_shared:             [],
      #     context_team_id:            'TB9QFHA9K',
      #     updated:                    1708619629639,
      #     parent_conversation:        null,
      #     creator:                    'UBAM2ECBG',
      #     is_ext_shared:              false,
      #     shared_team_ids:            ['TB9QFHA9K'],
      #     pending_connected_team_ids: [],
      #     is_member:                  true,
      #     last_read:                  '0000000000.000000',
      #     topic:                      { value: '', creator: '', last_set: 0 },
      #     purpose:                    { value: '', creator: '', last_set: 0 },
      #     previous_names:             [],
      #     priority:                   0
      #   }
      # }

      # call Slack API to create a new channel
      # slack_client.channel_invite(slack_channel_name, user_email)
      #   slack_channel_name: (String)
      #   user_email:         (String)
      def channel_invite(slack_channel_name, user_email)
        reset_attributes
        slack_channel_name = normalize_channel_name(slack_channel_name)
        user_email         = user_email.to_s
        @result            = {}

        if slack_channel_name.blank?
          @message = 'Slack channel required'
          return @result
        elsif user_email.blank?
          @message = 'Slack user email required'
          return @result
        elsif (user = self.user_find_by_email(user_email)).blank?
          reset_attributes
          @message = 'User email must be found in Slack workspace'
          @result  = {}
          return @result
        elsif (channel = self.channel_create(slack_channel_name)).blank?

          unless !self.success? && self.error == 429
            reset_attributes
            @message = 'Channel must be found in Slack workspace'
            @result  = {}
          end

          return @result
        end

        reset_attributes
        @result = {}

        body = {
          channel: channel.dig(:id).to_s,
          users:   [user.dig(:id).to_s]
        }

        slack_request(
          body:,
          error_message_prepend: 'Integrations::Slacker::Base.channel_invite',
          method:                'post',
          params:                nil,
          default_result:        {},
          url:                   "#{base_api_url}/conversations.invite"
        )

        if @success && @result.is_a?(Hash)
          response = @result.dig(:channel) || {}
        elsif !@success && @result.is_a?(Hash) && @result.dig(:error).to_s.casecmp?('channel_not_found')
          @message = 'Channel was NOT found in Slack'
        elsif !@success && @result.is_a?(Hash) && @result.dig(:error).to_s.casecmp?('already_in_channel')
          @success = true
          response = channel
        else
          response = {}
          @success = false
          @message = "Unexpected response: #{@result.inspect}" if @message.blank?
        end

        @result = response
      end
      # response (channel_not_found) ex:
      # {
      #   ok:    false,
      #   error: 'channel_not_found'
      # }

      # call Slack API for a list of channel name
      # slack_client.channel_names
      def channel_names
        reset_attributes
        @result = self.channels.pluck(:name)

        @result
      end

      # call Slack API for a list of users belonging to a channel
      # slack_client.channel_users(name (String))
      def channel_users(name)
        reset_attributes
        name    = normalize_channel_name(name)
        @result = []

        if name.blank?
          @message = 'Slack channel required'
          return @result
        elsif (channel = self.channel_create(name)).blank?
          reset_attributes
          @message = 'Channel must be found in Slack workspace'
          @result  = []
          return @result
        end

        next_cursor = ''
        response    = []
        params      = {
          limit:   200,
          channel: channel.dig(:id).to_s
        }

        loop do
          params[:cursor] = next_cursor

          slack_request(
            body:                  nil,
            error_message_prepend: 'Integrations::Slacker::Base.channel_users',
            method:                'post',
            params:,
            default_result:        {},
            url:                   "#{base_api_url}/conversations.members"
          )

          if @success && @result.is_a?(Hash)
            response   += @result.dig(:members)
            next_cursor = @result.dig(:response_metadata, :next_cursor).to_s
            break if next_cursor.blank?
          else
            response = []
            @success = false
            @message = "Unexpected response: #{@result.inspect}" if @message.blank?
            break
          end
        end

        @result = response
      end
      # response ex:
      # {
      #   ok:                true,
      #   members:           %w[UBAM2ECBG UE7MCPLLT U04CSN9B8JX],
      #   response_metadata: { next_cursor: '' }
      # }

      # call Slack API for a list of channels
      # slack_client.channels
      def channels
        reset_attributes

        next_cursor = ''
        response    = []
        params      = {
          limit:            200,
          exclude_archived: true
        }

        loop do
          params[:cursor] = next_cursor

          slack_request(
            body:                  nil,
            error_message_prepend: 'Integrations::Slacker::Base.channels',
            method:                'post',
            params:,
            default_result:        {},
            url:                   "#{base_api_url}/conversations.list"
          )

          if @success && @result.is_a?(Hash)
            response   += @result.dig(:channels)
            next_cursor = @result.dig(:response_metadata, :next_cursor).to_s
            break if next_cursor.blank?
          else
            response = []
            @success = false
            @message = "Unexpected response: #{@result.inspect}" if @message.blank?
            break
          end
        end

        @result = response
      end
      # response ex:
      # {
      #   ok:                true,
      #   channels:          [
      #     {
      #       id:                         'CB949DMDX',
      #       name:                       'features',
      #       is_channel:                 true,
      #       is_group:                   false,
      #       is_im:                      false,
      #       is_mpim:                    false,
      #       is_private:                 false,
      #       created:                    1_529_350_819,
      #       is_archived:                false,
      #       is_general:                 false,
      #       unlinked:                   0,
      #       name_normalized:            'features',
      #       is_shared:                  false,
      #       is_org_shared:              false,
      #       is_pending_ext_shared:      false,
      #       pending_shared:             [],
      #       context_team_id:            'TB9QFHA9K',
      #       updated:                    1_558_193_804_363,
      #       parent_conversation:        null,
      #       creator:                    'UBAMNRT0X',
      #       is_ext_shared:              false,
      #       shared_team_ids:            ['TB9QFHA9K'],
      #       pending_connected_team_ids: [],
      #       is_member:                  false,
      #       topic:                      { value: '', creator: '', last_set: 0 },
      #       purpose:                    { value: '', creator: '', last_set: 0 },
      #       previous_names:             [],
      #       num_members:                2
      #     }...
      #   ],
      #   response_metadata: { next_cursor: '' }
      # }
    end
  end
end
