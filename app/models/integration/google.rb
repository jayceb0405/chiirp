# frozen_string_literal: true

# app/models/integration/google.rb
module Integration
  class Google < ApplicationRecord
    # create a Google Business Messages Agent from a My Business Location
    # Integration::Google.create_agent_from_location(location)
    # (req) brand_id:               (String)
    # (req) client_api_integration: (ClientApiIntegration)
    # (req) ggl_client:             (Integrations::Ggl::Base)
    # (req) location:               (Google::MyBusinessLocation)
    def self.create_agent_from_location(client_api_integration, ggl_client, brand_id, location)
      response = { success: false, message: '', agent: nil }

      if (location_hours = location.dig(:regularHours, :periods)).blank?
        response[:message] = 'Location hours must be defined in Google.'
        return response
      elsif (name = location.dig(:title).to_s.presence).nil?
        response[:message] = 'Location title must be defined in Google.'
        return response
      elsif (phone_number = (location.dig(:phoneNumbers, :primaryPhone) || location.dig(:phoneNumbers)&.values&.first).to_s.presence).nil?
        response[:message] = 'Location phone number must be defined in Google.'
        return response
      elsif (website_url = location.dig(:websiteUri).to_s.presence).nil?
        response[:message] = 'Location website URL must be defined in Google.'
        return response
      end

      hours = {
        startTime: {
          hours:   location_hours.first.dig(:openTime, :hours) || 8,
          minutes: location_hours.first.dig(:openTime, :minutes) || 0
        },
        endTime:   {
          hours:   [location_hours.first.dig(:closeTime, :hours) || 17, 23].min,
          minutes: location_hours.first.dig(:closeTime, :minutes) || 0
        },
        timeZone:  client_api_integration.client.time_zone,
        startDay:  location_hours.first.dig(:openDay),
        endDay:    location_hours.last.dig(:openDay)
      }

      ggl_client.business_messages_create_agent(
        brand_id, {
          client_id:       client_api_integration.client_id,
          hours:,
          name:,
          phone_number:,
          website_url:,
          welcome_message: "Thanks for your message. We will get back to you within 24 hours. Kind regards, #{name} team."
        }
      )

      if ggl_client.success?
        response[:success] = true
        response[:agent]   = ggl_client.result
      else
        response[:message] = "A Google Agent could not be created. (#{ggl_client.message})"
      end

      response
    end

    # create Google Agents and request verification for selected Locations
    # Integration::Google.create_brand(client_api_integration, account, location)
    # (req) client_api_integration: (ClientApiIntegration)
    # (req) account_id:             (String)
    # (req) location_id:            (String)
    def self.create_brand(client_api_integration, account_id, location_id)
      response = { success: false, brand_id: nil, agent_id: nil, agent_launched: false, agent_verified: false, location_id: nil, location_launched: false, location_verified: false, message: '' }

      return response unless client_api_integration.is_a?(ClientApiIntegration) && account_id.to_s.present? && location_id.to_s.present? &&
                             (user_api_integration = UserApiIntegration.find_by(user_id: client_api_integration.user_id, target: 'google', name: '')) && self.valid_token?(user_api_integration) &&
                             (ggl_client = Integrations::Ggl::Base.new(user_api_integration.token, client_api_integration.client.tenant))

      #
      # Find or create a Google Business Messages Brand
      #   one Brand for each Location
      #
      if (brand_id = client_api_integration.active_locations_messages&.dig(account_id, location_id, 'brand_id').presence)
        ggl_client.business_messages_brand(brand_id)
        ggl_client.business_messages_create_brand(client_api_integration.client.name) unless ggl_client.success?
      else
        ggl_client.business_messages_create_brand(client_api_integration.client.name)
      end

      JsonLog.info 'Integration::Google.CreateBrand-brand', { result: ggl_client.faraday_result }

      brand_id = ggl_client.result&.dig(:name)

      if brand_id.blank?
        response[:message] = "A Google Business Messages Brand could not be created. (#{ggl_client.message})"
        return response
      end

      #
      # Find or create a Google Business Messages Agent for the Brand
      #
      my_business_location = ggl_client.my_business_location(location_id)

      if !(agent = ggl_client.business_messages_agents(brand_id)&.first.presence) && my_business_location.present?
        result = create_agent_from_location(client_api_integration, ggl_client, brand_id, my_business_location)

        agent = result[:agent] if result[:success]
      end

      JsonLog.info 'Integration::Google.CreateBrand-agent', { result: ggl_client.faraday_result }

      if agent.blank?
        response[:message] = "A Google Business Messages Agent could not be created. (#{ggl_client.message})"
        return response
      end

      #
      # Find or Create a Google Business Messages Location for the Agent
      #
      unless (locations = ggl_client.business_messages_locations(brand_id)).present? && (business_messages_location = locations.find { |l| l.dig(:agent) == agent.dig(:name) })
        ggl_client.business_messages_create_location(brand_id, agent.dig(:name), my_business_location.dig(:metadata, :placeId))

        business_messages_location = ggl_client.result if ggl_client.success?
      end

      JsonLog.info 'Integration::Google.CreateBrand.location', { result: ggl_client.faraday_result }

      if business_messages_location.blank?
        response[:message] = "A Google Business Messages Location could not be created. (#{ggl_client.message})"
        return response
      end

      response[:success]     = true
      response[:brand_id]    = brand_id
      response[:agent_id]    = agent.dig(:name)
      response[:location_id] = business_messages_location.dig(:name)

      response[:agent_verified] = ggl_client.business_messages_verified_agent(response[:agent_id])&.dig(:verificationState).to_s.casecmp?('VERIFICATION_STATE_VERIFIED')
      response[:agent_verified] = ggl_client.business_messages_verify_agent(response[:agent_id], my_business_location.dig(:websiteUri))&.dig(:verificationState).to_s.casecmp?('VERIFICATION_STATE_VERIFIED') unless response[:agent_verified]

      response[:location_verified] = ggl_client.business_messages_verified_location(response[:location_id])&.dig(:verificationState).to_s.casecmp?('VERIFICATION_STATE_VERIFIED')
      response[:location_verified] = ggl_client.business_messages_verify_location(response[:location_id])&.dig(:verificationState).to_s.casecmp?('VERIFICATION_STATE_VERIFIED') unless response[:location_verified]

      response[:agent_launched] = ggl_client.business_messages_launched_agent(response[:agent_id])&.dig(:businessMessages, :launchDetails, :LOCATION, :launchState).to_s.casecmp?('LAUNCH_STATE_LAUNCHED')
      response[:agent_launched] = ggl_client.business_messages_launch_agent(response[:agent_id])&.dig(:businessMessages, :launchDetails, :LOCATION, :launchState).to_s.casecmp?('LAUNCH_STATE_LAUNCHED') unless response[:agent_launched]

      response[:location_launched] = ggl_client.business_messages_launched_location(response[:location_id])&.dig(:launchState).to_s.casecmp?('LAUNCH_STATE_LAUNCHED')
      response[:location_launched] = ggl_client.business_messages_launch_location(response[:location_id])&.dig(:launchState).to_s.casecmp?('LAUNCH_STATE_LAUNCHED') unless response[:location_launched]

      JsonLog.info 'Integration::Google.CreateBrand-response', { result: ggl_client.faraday_result }

      client_api_integration.active_locations_messages[account_id][location_id] = response.except(:success, :message)
      client_api_integration.agents << response[:agent_id] unless client_api_integration.agents.include?(response[:agent_id])
      client_api_integration.save

      response
    end

    # delete Google Agents and request verification for selected Locations
    # Integration::Google.delete_brand(client_api_integration, account, location)
    # (req) client_api_integration: (ClientApiIntegration)
    # (req) account_id:             (String)
    # (req) location_id:            (String)
    def self.delete_brand(client_api_integration, account_id, location_id)
      return unless client_api_integration.is_a?(ClientApiIntegration) && account_id.to_s.present? && location_id.to_s.present? &&
                    (brand_id = client_api_integration.active_locations_messages&.dig(account_id, location_id, 'brand_id').presence) &&
                    (user_api_integration = UserApiIntegration.find_by(user_id: client_api_integration.user_id, target: 'google', name: '')) && self.valid_token?(user_api_integration) &&
                    (ggl_client = Integrations::Ggl::Base.new(user_api_integration.token, client_api_integration.client.tenant))

      ggl_client.business_messages_delete_brand(brand_id)
    end

    # get Google reviews for all Users/Accounts/Locations
    # should be started by ClockWork
    # Integration::Google.load_all_reviews
    def self.load_all_reviews
      return if DelayedJob.find_by(process: 'google_reviews_load')

      ClientApiIntegration.where(target: 'google', name: '').find_each do |client_api_integration|
        start_date = client_api_integration.last_start_date.to_s
        run_at     = Time.current
        client_api_integration.update(last_start_date: Time.current.iso8601)

        client_api_integration.active_locations_reviews&.each do |account, locations|
          locations.each do |location|
            self.delay(
              run_at:,
              priority:      DelayedJob.job_priority('google_reviews_load'),
              queue:         DelayedJob.job_queue('google_reviews_load'),
              user_id:       client_api_integration.user_id,
              group_process: 1,
              process:       'google_reviews_load',
              data:          { client_api_integration:, account:, location:, start_date: }
            ).load_reviews(client_api_integration, account, location, start_date)
            # self.load_reviews(client_api_integration, account, location, start_date)
            run_at += 2.minutes
          end
        end
      end
    end

    # get Google reviews and group into blocks of 10
    # Integration::Google.load_reviews(ClientApiIntegration, account, location, start_date)
    def self.load_reviews(client_api_integration, account, location, start_date)
      return unless client_api_integration.is_a?(ClientApiIntegration) && account.to_s.present? && location.to_s.present? &&
                    (user_api_integration = UserApiIntegration.find_by(user_id: client_api_integration.user_id, target: 'google', name: '')) && self.valid_token?(user_api_integration) &&
                    (ggl_client = Integrations::Ggl::Base.new(user_api_integration.token, client_api_integration.client.tenant))

      reviews = ggl_client.reviews(account, location, start_date)
      index   = 0
      run_at  = Time.current

      while index <= reviews.length
        self.delay(
          run_at:,
          priority:      DelayedJob.job_priority('google_reviews_load'),
          queue:         DelayedJob.job_queue('google_reviews_load'),
          user_id:       client_api_integration.user_id,
          group_process: 0,
          process:       'google_reviews_load',
          data:          { client_api_integration:, reviews: reviews[index..(index + 9)] }
        ).save_reviews_block(client_api_integration, reviews[index..(index + 9)])
        # self.save_reviews_block(client_api_integration, reviews[index..(index + 9)])
        index  += 10
        run_at += 1.minute
      end
    end

    # process actions for a Google Review
    # Integration::Google.process_actions_for_review(ClientApiIntegration, Contact, Review)
    def self.process_actions_for_review(client_api_integration, contact, review)
      return unless (star_actions = client_api_integration.actions_reviews.dig(review.star_rating.to_s))

      contact.process_actions(
        campaign_id:       star_actions.dig('campaign_id'),
        group_id:          star_actions.dig('group_id'),
        stage_id:          star_actions.dig('stage_id'),
        tag_id:            star_actions.dig('tag_id'),
        stop_campaign_ids: star_actions.dig('stop_campaign_ids')
      )
    end

    # Revoke a Google Oauth2 token
    # Integration::Google.revoke_token(user_api_integration)
    # (req) user_api_integration: (UserApiIntegration)
    def self.revoke_token(user_api_integration)
      return if user_api_integration.token.blank?

      if Integration::Google.valid_token?(user_api_integration)
        ggl_client = Integrations::Ggl::Base.new(user_api_integration.token, I18n.t('tenant.id'))
        ggl_client.revoke_token

        user_api_integration.update(token: '', refresh_token: '') if ggl_client.success?
      else
        user_api_integration.update(token: '', refresh_token: '')
      end
    end

    # save/update a Google review to Reviews
    # Integration::Google.save_review(ClientApiIntegration, Hash)
    def self.save_review(client_api_integration, data)
      review = nil

      return review unless client_api_integration.is_a?(ClientApiIntegration) && data.is_a?(Hash)

      data         = data.deep_symbolize_keys
      contact_name = data.dig(:reviewer, :displayName).to_s.parse_name

      if (review = Review.find_or_initialize_by(client_id: client_api_integration.client_id, review_id: data.dig(:reviewId)))
        new_review = review.new_record?
        contact    = review.contact || Contact.find_by_closest_match(client_api_integration.client_id, contact_name.dig(:lastname).to_s, contact_name.dig(:firstname).to_s)

        return nil unless review.update(
          contact_id:        contact&.id,
          name:              data.dig(:reviewer, :displayName).to_s,
          star_rating:       %w[zero one two three four five].index(data.dig(:starRating).to_s.downcase),
          comment:           data.dig(:comment).to_s,
          target:            'google',
          target_created_at: data.dig(:createTime),
          target_updated_at: data.dig(:updateTime),
          account:           (data.dig(:name)&.split('/') || '')[0, 2]&.join('/'),
          location:          (data.dig(:name)&.split('/') || '')[2, 2]&.join('/')
        )

        if new_review && review.target_created_at >= 1.day.ago

          if (user = contact&.user || User.find_by(client: client_api_integration.client, id: client_api_integration.user_id)) && user.access_controller?('integrations', 'user')
            app_host = I18n.with_locale(client_api_integration.client.tenant) { I18n.t("tenant.#{Rails.env}.app_host") }
            content  = ''

            if review.contact_id.present? && user.notifications.dig('review', 'matched')
              content = "New #{review.star_rating} Star Review received from #{contact.fullname}!"
              url     = Rails.application.routes.url_helpers.central_url(contact_id: contact.id, host: app_host)
            elsif review.contact_id.blank? && user.notifications.dig('review', 'unmatched')
              content = "New #{review.star_rating} Star Review received from unknown Contact!"
              url     = Rails.application.routes.url_helpers.integrations_google_integrations_url(host: app_host)
            end

            if content.present?
              if user.notifications.dig('review', 'by_push').to_bool
                Users::SendPushJob.perform_later(
                  content:,
                  url:,
                  user_id: user.id
                )
              end

              if user.notifications.dig('review', 'by_text')
                user.delay(
                  priority:   DelayedJob.job_priority('send_text'),
                  queue:      DelayedJob.job_queue('send_text'),
                  user_id:    user.id,
                  contact_id: contact&.id.to_i,
                  process:    'send_text',
                  data:       { content: "#{content} #{url}" }
                ).send_text(content: "#{content} #{url}")
              end
            end
          end

          self.process_actions_for_review(client_api_integration, contact, review) if contact
        end
      end

      review
    end
    # example review:
    #  {
    #    "reviewId":"AbFvOqllIQFfqZq0t4PFJFt54VjdpzwbjBlRFO13IyKgYwN4ZNgZLsl5lXd0ySxvJ4zLyALVTCI1Tw",
    #    "reviewer":{
    #      "profilePhotoUrl":"https://lh3.googleusercontent.com/a-/ALV-UjXPd_uUE6n658Gppj8lctgr9bE4XMcgtCkMh6h-_QYEgwpd=s120-c-rp-mo-br100",
    #      "displayName":"Bryan Mosier"
    #    },
    #    "starRating":"FIVE",
    #    "createTime":"2022-05-16T11:27:14.829390Z",
    #    "updateTime":"2022-05-16T11:27:14.829390Z",
    #    "reviewReply":{
    #      "comment":"Thanks for letting us take care of your homes heat and air conditioning needs.",
    #      "updateTime":"2022-05-17T15:18:52.509033Z"
    #    },
    #    "name":"accounts/106509872556840346245/locations/18310729826786066313/reviews/AbFvOqllIQFfqZq0t4PFJFt54VjdpzwbjBlRFO13IyKgYwN4ZNgZLsl5lXd0ySxvJ4zLyALVTCI1Tw"
    #  }

    # save a block of 10 reviews
    # Integration::Google.save_reviews_block(ClientApiIntegration, Array)
    def self.save_reviews_block(client_api_integration, reviews)
      return unless client_api_integration.is_a?(ClientApiIntegration) && reviews.is_a?(Array)

      reviews.each do |review|
        self.save_review(client_api_integration, review)
      end
    end

    # authorize a User to edit Google Revews Configuration
    # Integration::Google.user_authorized_for_accounts_locations_config?(current_user, client_api_integration)
    def self.user_authorized_for_accounts_locations_config?(current_user, client_api_integration)
      (current_user.access_controller?('integrations', 'google_messages') || current_user.access_controller?('integrations', 'google_reviews')) &&
        (client_api_integration.user_id.to_i.zero? || client_api_integration.user_id.to_i == current_user.id ||
        (client_api_integration.active_accounts.blank? && client_api_integration.active_locations_reviews.blank?) ||
        client_api_integration.client.users.find_by(id: client_api_integration.user_id).nil?)
    end

    # Validate a Google Oauth2 token & refresh if necessary
    # Integration::Google.valid_token?(user_api_integration)
    # (req) user_api_integration: (UserApiIntegration)
    def self.valid_token?(user_api_integration)
      return false if user_api_integration&.token.blank? || user_api_integration&.refresh_token.blank?

      ggl_client  = Integrations::Ggl::Base.new(user_api_integration.token, I18n.t('tenant.id'))
      valid_token = ggl_client.valid_token?(user_api_integration.refresh_token)
      user_api_integration.update(token: ggl_client.token) if ggl_client.token.present?

      valid_token
    end
  end
end
