# frozen_string_literal: true

# app/lib/integrations/ggl/business_messages/agents.rb
module Integrations
  module Ggl
    module BusinessMessages
      # Google Agents methods called by Google Messages class
      # ggl_client = Integrations::Ggl::Base.new(token, I18n.t('tenant.id'))
      module Agents
        def business_messages_agent(agent_id)
          reset_attributes
          @result = []

          if agent_id.blank?
            @message = 'Agent ID required.'
            return @result
          end

          self.google_request(
            body:                  nil,
            error_message_prepend: 'Integrations::Ggl::BusinessMessages::Agents.BusinessMessagesAgent',
            method:                'get',
            params:                nil,
            default_result:        @result,
            url:                   "#{agents_base_url}/#{agents_base_version}/#{agent_id}"
          )

          @result
        end

        def business_messages_agents(brand_id)
          reset_attributes
          @result = []

          if brand_id.blank?
            @message = 'Brand ID required'
            return @result
          end

          self.google_request(
            body:                  nil,
            error_message_prepend: 'Integrations::Ggl::BusinessMessages::Agents.BusinessMessagesAgents',
            method:                'get',
            params:                nil,
            default_result:        @result,
            url:                   "#{agents_base_url}/#{agents_base_version}/#{brand_id}/agents"
          )

          @result = @result&.dig(:agents)
        end

        # hours format example
        # {
        #   startTime: {
        #     {
        #       "hours": integer,
        #       "minutes": integer,
        #       "seconds": integer,
        #       "nanos": integer
        #     }
        #   },
        #   endTime: {
        #     {
        #       "hours": integer,
        #       "minutes": integer,
        #       "seconds": integer,
        #       "nanos": integer
        #     }
        #   },
        #   timeZone: string,
        #   startDay: enum (DayOfWeek),
        #   endDay: enum (DayOfWeek)
        # }
        # create a new Agent
        # ggl_client.business_messages_create_agent()
        # (req) brand_id:        (String)
        # (req) client_id:       (Integer)
        # (req) hours:           (Array)
        # (req) name:            (String)
        # (req) phone_number:    (String)
        # (req) website_url:     (String)
        # (req) welcome_message: (String)
        def business_messages_create_agent(brand_id, args = {})
          reset_attributes
          @result         = {}
          client_id       = args.dig(:client_id).to_s
          domain          = args.dig(:domain).to_s
          hours           = args.dig(:hours)
          name            = args.dig(:name).to_s
          phone_number    = args.dig(:phone_number).to_s.clean_phone
          website_url     = args.dig(:website_url).to_s
          welcome_message = args.dig(:welcome_message).to_s

          if domain.blank?
            domain = website_url
            domain = "https://#{domain}" unless domain.start_with?('http://', 'https://')
            domain = URI.parse(domain).host
          end

          if brand_id.blank?
            @message = 'Brand ID is required.'
            return @result
          elsif client_id.blank?
            @message = 'Client ID is required.'
            return @result
          elsif domain.blank?
            @message = 'Domain is required.'
            return @result
          elsif hours.blank?
            @message = 'Hours are required.'
            return @result
          elsif name.blank?
            @message = 'Agent name is required.'
            return @result
          elsif phone_number.blank?
            @message = 'Business Phone Number is required.'
            return @result
          elsif website_url.blank?
            @message = 'Website URL is required.'
            return @result
          elsif welcome_message.blank?
            @message = 'Welcome Message is required.'
            return @result
          end

          hours[:timeZone]   = ActiveSupport::TimeZone::MAPPING.find { |k, _v| k == hours.dig(:timeZone) }&.last
          logo_url           = args.dig(:logo_url).to_s
          offline_message    = args.dig(:offline_message).to_s
          privacy_policy_url = args.dig(:privacy_policy_url).to_s
          test_url           = args.dig(:test_url).to_s

          body = {
            name:                  client_id,
            displayName:           name,
            businessMessagesAgent: {
              logoUrl:                 logo_url,
              entryPointConfigs:       [
                {
                  allowedEntryPoint: 'LOCATION'
                }
              ],
              conversationalSettings:  {
                en: {
                  welcomeMessage: {
                    text: welcome_message
                  },
                  offlineMessage: {
                    text: offline_message
                  },
                  privacyPolicy:  {
                    url: privacy_policy_url
                  }
                }
              },
              defaultLocale:           'en',
              primaryAgentInteraction: {
                interactionType:     'HUMAN',
                humanRepresentative: {
                  humanMessagingAvailability: {
                    hours:
                  }
                }
              },
              customAgentId:           client_id,
              testUrls:                [
                {
                  surface: 'SURFACE_UNSPECIFIED',
                  url:     test_url
                }
              ]
            }
          }

          self.google_request(
            body:,
            error_message_prepend: 'Integrations::Ggl::BusinessMessages::Agents.BusinessMessagesCreateAgent',
            method:                'post',
            params:                nil,
            default_result:        @result,
            url:                   "#{agents_base_url}/#{agents_base_version}/#{brand_id}/agents"
          )

          # if @result.success?
          #   @result  = {
          #     name: @result.dig(:displayName),
          #     id: @result.dig(:name).sub("brands/#{brand_id}/agents/", ''),
          #     test_urls: {
          #       android_web: @result.dig(:businessMessagesAgent, :testUrls).find { |url| url.dig(:surface).to_s == 'SURFACE_ANDROID_WEB' }&.dig(:url).to_s,
          #       android_maps: @result.dig(:businessMessagesAgent, :testUrls).find { |url| url.dig(:surface).to_s == 'SURFACE_ANDROID_MAPS' }&.dig(:url).to_s,
          #       ios_maps: @result.dig(:businessMessagesAgent, :testUrls).find { |url| url.dig(:surface).to_s == 'SURFACE_IOS_MAPS' }&.dig(:url).to_s,
          #     }
          #   }
          # end

          @result
        end

        def business_messages_delete_agent(brand_id)
          reset_attributes
          @result = {}

          if brand_id.blank?
            @message = 'Brand ID required.'
            return @result
          end

          self.google_request(
            body:                  nil,
            error_message_prepend: 'Integrations::Ggl::BusinessMessages::Agents.BusinessMessagesDeleteAgent',
            method:                'delete',
            params:                nil,
            default_result:        @result,
            url:                   "#{agents_base_url}/#{agents_base_version}/#{brand_id}"
          )

          @result
        end

        # Launch a Google Business Messages Agent
        # ggl_client.business_messages_launch_agent(agent_id)
        # (req) agent_id:    (String)
        def business_messages_launch_agent(agent_id)
          reset_attributes
          @result = {}

          if agent_id.blank?
            @message = 'Agent ID required.'
            return @result
          end

          body = {
            agentLaunch: {
              name:             agent_id,
              businessMessages: {
                launchDetails: {
                  LOCATION: {
                    entryPoint: 'LOCATION'
                  }
                }
              }
            }
          }

          self.google_request(
            body:,
            error_message_prepend: 'Integrations::Ggl::BusinessMessages::Agents.BusinessMessagesLaunchAgent',
            method:                'post',
            params:                nil,
            default_result:        @result,
            url:                   "#{agents_base_url}/#{agents_base_version}/#{agent_id}:requestLaunch"
          )

          @result
        end
        # {
        #   :name=>"brands/85851e0e-8406-4812-8d15-53feecfa3b84/agents/bc69bbee-878a-4cda-a400-bec9311040e7/launch",
        #   :businessMessages=>{
        #     :launchDetails=>{
        #       :LOCATION=>{
        #         :entryPoint=>"LOCATION",
        #         :launchState=>"LAUNCH_STATE_LAUNCHED"
        #       }
        #     }
        #   }
        # }

        # Check launch status of a Google Business Messages Agent
        # ggl_client.business_messages_launched_agent(agent_id)
        # (req) agent_id: (String)
        def business_messages_launched_agent(agent_id)
          reset_attributes
          @result = {}

          if agent_id.blank?
            @message = 'Agent ID required.'
            return @result
          end

          self.google_request(
            body:                  nil,
            error_message_prepend: 'Integrations::Ggl::BusinessMessages::Agents.BusinessMessagesLaunchedAgent',
            method:                'get',
            params:                nil,
            default_result:        @result,
            url:                   "#{agents_base_url}/#{agents_base_version}/#{agent_id}/launch"
          )

          @result
        end
        # {
        #   :name=>"brands/85851e0e-8406-4812-8d15-53feecfa3b84/agents/bc69bbee-878a-4cda-a400-bec9311040e7/launch",
        #   :businessMessages=>{
        #     :launchDetails=>{
        #       :LOCATION=>{
        #         :entryPoint=>"LOCATION",
        #         :launchState=>"LAUNCH_STATE_LAUNCHED"
        #       }
        #     }
        #   }
        # }

        # Unlaunch a Google Business Messages Agent
        # ggl_client.business_messages_unlaunch_agent(agent_id)
        # (req) agent_id:    (String)
        def business_messages_unlaunch_agent(agent_id)
          reset_attributes
          @result = {}

          if agent_id.blank?
            @message = 'Agent ID required.'
            return @result
          end

          body = {
            businessMessages: {
              launchDetails: {
                LOCATION: {
                  entryPoint:  'LOCATION',
                  launchState: 'LAUNCH_STATE_UNLAUNCHED'
                }
              }
            }
          }

          self.google_request(
            body:,
            error_message_prepend: 'Integrations::Ggl::BusinessMessages::Agents.BusinessMessagesUnlaunchAgent',
            method:                'patch',
            params:                nil,
            default_result:        @result,
            url:                   "#{agents_base_url}/#{agents_base_version}/#{agent_id}/launch"
          )

          @result
        end
        # {
        #   :name=>"brands/85851e0e-8406-4812-8d15-53feecfa3b84/agents/bc69bbee-878a-4cda-a400-bec9311040e7/launch",
        #   :businessMessages=>{
        #     :launchDetails=>{
        #       :LOCATION=>{
        #         :entryPoint=>"LOCATION",
        #         :launchState=>"LAUNCH_STATE_UNLAUNCHED"
        #       }
        #     }
        #   }
        # }

        # Verify a Google BusinessMessages Agent
        # ggl_client.business_messages_unverify_agent(agent_id)
        # (req) agent_id:    (String)
        # verificationStates: VERIFICATION_STATE_UNSPECIFIED / VERIFICATION_STATE_UNVERIFIED / VERIFICATION_STATE_PENDING / VERIFICATION_STATE_VERIFIED / VERIFICATION_STATE_SUSPENDED_IN_GMB
        def business_messages_unverify_agent(agent_id)
          reset_attributes
          @result = {}

          if agent_id.blank?
            @message = 'Agent ID required.'
            return @result
          end

          body = { verificationState: 'VERIFICATION_STATE_UNVERIFIED' }

          self.google_request(
            body:,
            error_message_prepend: 'Integrations::Ggl::BusinessMessages::Agents.BusinessMessagesUnverifyAgent',
            method:                'patch',
            params:                nil,
            default_result:        @result,
            url:                   "#{agents_base_url}/#{agents_base_version}/#{agent_id}/verification"
          )

          @result
        end
        # {
        #   :name=>"brands/634af61e-f5af-4869-9c63-de21c1f8b724/agents/3dd90818-8081-4f6e-991e-153da306fb09/verification",
        #   :verificationState=>"VERIFICATION_STATE_UNVERIFIED",
        #   :agentVerificationContact=>{}
        # }

        # Check verification of a Google BusinessMessages Agent
        # ggl_client.business_messages_verified_agent(agent_id)
        # (req) agent_id: (String)
        # verificationStates: VERIFICATION_STATE_UNSPECIFIED / VERIFICATION_STATE_UNVERIFIED / VERIFICATION_STATE_PENDING / VERIFICATION_STATE_VERIFIED / VERIFICATION_STATE_SUSPENDED_IN_GMB
        def business_messages_verified_agent(agent_id)
          reset_attributes
          @result = {}

          if agent_id.blank?
            @message = 'Agent ID required.'
            return @result
          end

          self.google_request(
            body:                  nil,
            error_message_prepend: 'Integrations::Ggl::BusinessMessages::Agents.BusinessMessagesVerifiedAgent',
            method:                'get',
            params:                nil,
            default_result:        @result,
            url:                   "#{agents_base_url}/#{agents_base_version}/#{agent_id}/verification"
          )

          @result
        end
        # {
        #   :name=>"brands/634af61e-f5af-4869-9c63-de21c1f8b724/agents/3dd90818-8081-4f6e-991e-153da306fb09/verification",
        #   :verificationState=>"VERIFICATION_STATE_UNVERIFIED",
        #   :agentVerificationContact=>{}
        # }

        # Verify a Google BusinessMessages Agent
        # ggl_client.business_messages_verify_agent(agent_id, website_url)
        # (req) agent_id:    (String)
        # (req) website_url: (String)
        # verificationStates: VERIFICATION_STATE_UNSPECIFIED / VERIFICATION_STATE_UNVERIFIED / VERIFICATION_STATE_PENDING / VERIFICATION_STATE_VERIFIED / VERIFICATION_STATE_SUSPENDED_IN_GMB
        def business_messages_verify_agent(agent_id, website_url)
          reset_attributes
          @result = {}

          if agent_id.blank?
            @message = 'Agent ID required.'
            return @result
          elsif website_url.blank?
            @message = 'Website URL required.'
            return @result
          end

          body = {
            agentVerificationContact: {
              partnerName:              'Hwy 18, LLC (Chiirp)',
              partnerEmailAddress:      'kevin@chiirp.com',
              brandContactName:         'Hwy 18, LLC (Chiirp)',
              brandContactEmailAddress: 'kevin@chiirp.com',
              brandWebsiteUrl:          website_url
            }
          }

          self.google_request(
            body:,
            error_message_prepend: 'Integrations::Ggl::BusinessMessages::Agents.BusinessMessagesVerifyAgent',
            method:                'post',
            params:                nil,
            default_result:        @result,
            url:                   "#{agents_base_url}/#{agents_base_version}/#{agent_id}:requestVerification"
          )

          @result
        end
        # {
        #   :name=>"brands/634af61e-f5af-4869-9c63-de21c1f8b724/agents/3dd90818-8081-4f6e-991e-153da306fb09/verification",
        #   :verificationState=>"VERIFICATION_STATE_UNVERIFIED",
        #   :agentVerificationContact=>{}
        # }

        private

        def agents_base_url
          'https://businesscommunications.googleapis.com'
        end

        def agents_base_version
          'v1'
        end

        def parse_agent(args)
          {
            brand_id:           args.dig(:name).to_s.split('/')[1].to_s,
            agent_id:           args.dig(:name).to_s.split('/')[3].to_s,
            name:               args.dig(:displayName).to_s,
            welcome_message:    args.dig(:businessMessagesAgent, :conversationalSettings, :en, :welcomeMessage, :text).to_s,
            offline_message:    args.dig(:businessMessagesAgent, :conversationalSettings, :en, :offlineMessage, :text).to_s,
            privacy_policy_url: args.dig(:businessMessagesAgent, :conversationalSettings, :en, :privacyPolicy, :url).to_s,
            hours:              args.dig(:businessMessagesAgent, :primaryAgentInteraction, :humanRepresentative, :humanMessagingAvailability, :hours).first,
            website_url:        args.dig(:businessMessagesAgent, :nonLocalConfig, :contactOption, :url).to_s,
            logo_url:           '',
            domain:             args.dig(:businessMessagesAgent, :nonLocalConfig, :enabledDomains).first,
            phone_number:       args.dig(:businessMessagesAgent, :nonLocalConfig, :phoneNumber, :number).to_s.sub('+1', '')
          }
        end
        # {
        #   :name=>"brands/3ab41a9d-231b-4ead-a43d-bf17dcd4a972/agents/32321f45-8750-4b1e-b572-630186198633",
        #   :displayName=>"Test",
        #   :businessMessagesAgent=>{
        #     :entryPointConfigs=>[
        #       {:allowedEntryPoint=>"NON_LOCAL"}
        #     ],
        #     :conversationalSettings=>{
        #       :en=>{
        #         :welcomeMessage=>{:text=>"Welcome"},
        #         :privacyPolicy=>{:url=>"https://chiirp.com"},
        #         :offlineMessage=>{:text=>"Now offline"}
        #       }
        #     },
        #     :primaryAgentInteraction=>{
        #       :interactionType=>"HUMAN",
        #       :humanRepresentative=>{
        #         :humanMessagingAvailability=>{:hours=>[{:startTime=>{:hours=>8}, :endTime=>{:hours=>18}, :timeZone=>"America/New_York"}]}
        #       }
        #     },
        #     :customAgentId=>"1234",
        #     :defaultLocale=>"en",
        #     :authorizationConfig=>{},
        #     :nonLocalConfig=>{
        #       :contactOption=>{
        #         :url=>"https://dev.chiirp.com",
        #         :options=>["EMAIL"]
        #       },
        #       :enabledDomains=>["chiirp.com"],
        #       :phoneNumber=>{:number=>"+18023455136"},
        #       :callDeflectionPhoneNumbers=>[{:number=>"+18023455136"}],
        #       :regionCodes=>["US"]
        #     },
        #     :surveyConfig=>{},
        #     :dialogflowAssociation=>{
        #       :dfServiceAccountEmail=>"bm-dialogflow@gbc-chiirp-hwy-18-llc-fxgcmc0.iam.gserviceaccount.com",
        #       :enableAutoResponse=>false
        #     }
        #   }
        # }
      end
    end
  end
end
