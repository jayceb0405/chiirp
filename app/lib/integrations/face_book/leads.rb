# frozen_string_literal: true

# app/lib/integrations/face_book/leads.rb
module Integrations
  module FaceBook
    module Leads
      # get a lead from a Facebook Page
      # fb_client.page_lead()
      # Integrations::FaceBook::Base.new.page_lead()
      #   (req) page_token: (String)
      #   (req) lead_id:    (String)
      def page_lead(**args)
        reset_attributes
        @result = {}

        if args.dig(:page_token).blank?
          @message = 'Facebook Page token is required'
          return @result
        elsif args.dig(:lead_id).blank?
          @message = 'Facebook Lead ID is required'
          return @result
        end

        facebook_request(
          body:                  nil,
          error_message_prepend: 'Integrations::FaceBook::Leads.page_lead',
          method:                'get',
          params:                { access_token: args[:page_token], fields: 'id,form_id,field_data,created_time' },
          default_result:        @result,
          url:                   "#{base_api_url}/#{api_version}/#{args[:lead_id]}"
        )

        @result
      end
      # example Facebook response
      # {
      #   id:           '928754215787810',
      #   form_id:      '320301552296525',
      #   field_data:   [
      #     {
      #       name:   'phone_number',
      #       values: ['+14433086575']
      #     },
      #     {
      #       name:   'full_name',
      #       values: ['Katerin Gamez']
      #     }
      #   ],
      #   created_time: '2024-11-08T23:23:11+0000'
      # }

      # get forms for a Facebook Page
      # fb_client.page_lead_forms()
      # Integrations::FaceBook::Base.new.page_lead_forms()
      #   (req) page_token: (String)
      #   (req) page_id:    (String)
      def page_lead_forms(**args)
        reset_attributes
        @result = {}

        if args.dig(:page_token).blank?
          @message = 'Facebook Page token is required'
          return @result
        elsif args.dig(:page_id).blank?
          @message = 'Facebook Page ID is required'
          return @result
        end

        data   = []
        params = { access_token: args[:page_token], fields: 'id,name,status,page,questions,leads_count' }
        url    = "#{base_api_url}/#{api_version}/#{args[:page_id]}/leadgen_forms"

        loop do
          facebook_request(
            body:                  nil,
            error_message_prepend: 'Integrations::FaceBook::Leads.page_lead_forms',
            method:                'get',
            params:,
            default_result:        {},
            url:
          )

          data += @result.dig(:data)
          Rails.logger.info "data.map(&:name): #{data.map { |d| d[:name] }.inspect} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"
          Rails.logger.info "data.length: #{data.length.inspect} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"
          break unless @result.dig(:paging, :next).present?

          params = nil
          url    = @result.dig(:paging, :next)
        end

        @result[:data] = data

        @result
      end
      # example Facebook response
      # { data:   [
      #     { id:          '475035917572894',
      #       name:        '2022 Special Offer',
      #       status:      'ACTIVE',
      #       page:        { name: 'Chiirp', id: '298964710698004' },
      #       questions:   [{ key: 'what_kind_of_business_are_you_in?_', label: 'What kind of business are you in?', type: 'CUSTOM', id: '487563962717667' },
      #                     { key: 'full_name', label: 'Full name', type: 'FULL_NAME', id: '448949863369085' },
      #                     { key: 'email', label: 'Email', type: 'EMAIL', id: '1948430065329831' },
      #                     { key: 'phone_number', label: 'Phone number', type: 'PHONE', id: '667505857745568' }],
      #       leads_count: 0 },
      #     { id:          '355436802643565',
      #       name:        'Improve Your Communication - Double Your Sales',
      #       status:      'ACTIVE',
      #       page:        { name: 'Chiirp', id: '298964710698004' },
      #       questions:   [{ key: 'email', label: 'Email', type: 'EMAIL', id: '509411336989953' },
      #                     { key: 'full_name', label: 'Full name', type: 'FULL_NAME', id: '956800921781940' },
      #                     { key: 'phone_number', label: 'Phone number', type: 'PHONE', id: '152440090313334' }],
      #       leads_count: 0 },
      #     { id:          '481619243165427',
      #       name:        'What kind of business survey',
      #       status:      'ACTIVE',
      #       page:        { name: 'Chiirp', id: '298964710698004' },
      #       questions:   [{ key:     'are_you_currently_running_ads_for_your_business?_',
      #                       label:   'Are you currently running ads for your business?',
      #                       options: [{ key: 'yes', value: 'Yes' }, { key: 'no', value: 'No' }],
      #                       type:    'CUSTOM',
      #                       id:      '976820606190971' },
      #                     { key:     'how_many_employees_at_your_company?_',
      #                       label:   'How many employees at your company?',
      #                       options: [{ key: '1-5', value: '1-5' }, { key: '6-10', value: '6-10' }, { key: '11-50', value: '11-50' }, { key: '50+', value: '50+' }],
      #                       type:    'CUSTOM',
      #                       id:      '4148194511897449' },
      #                     { key:     'would_you_be_willing_to_jump_on_a_quick_10_minute_demo_to_see_how_this_all_works?_',
      #                       label:   'Would you be willing to jump on a quick 10 minute demo to see how this all works?',
      #                       options: [{ key: 'yes', value: 'Yes' }, { key: 'no', value: 'No' }],
      #                       type:    'CUSTOM',
      #                       id:      '983851719028117' },
      #                     { key: 'what_kind_of_business_are_you_in?_', label: 'What kind of business are you in?', type: 'CUSTOM', id: '2870422593203305' },
      #                     { key: 'email', label: 'Email', type: 'EMAIL', id: '749793719053688' },
      #                     { key: 'full_name', label: 'Full name', type: 'FULL_NAME', id: '271809734621737' },
      #                     { key: 'phone_number', label: 'Phone number', type: 'PHONE', id: '2818628395118959' }],
      #       leads_count: 0 }, ...
      #   ],
      #   paging: { cursors: {
      #               before: 'QVFIUi1JSXViSjNFVW5naWFLZAG1FeDNLOVhXLU1JeFpmOGZAOMVgxRVE4dzRfZAlNuWC05b1RFVzUwWTBQZAnRubzZAPZA0g5SkVoS3c4b01JWnlnQU82S2pYaERB',
      #               after:  'QVFIUlNTcWEyM00yRnIyejduakQzYkxZAUHJBZAHpkeFBVN2tkSnlrSlcxQXdBR3NOWjY1WEMwSHczczRfYkJORmZA4OElSUmVjb3BLZAExvS3I5ZA1A2dUFmWnhR'
      #             },
      #             next:    'https://graph.facebook.com/v21.0/298964710698004/leadgen_forms?access_token=EAAJ34loVljgBOZBaZAOTbx3yZAr7ZB2q8JeEJ3wsxVO8lipBTp8ATAcam1wHfitqPIw283P4X9pOIZBzJENYZC86lAXNuHcuPYI22QC23IFZB8XrpmwSKCDIvpwgF8qms0YtiGzdpa5mK3XeVp1ILFcsuqXZCLRxXV9fI8oZC31ZA8DFOuAtdxfVdgRJSe1xmRBZBZABPSuV1WZAjRu0Uu7gP&fields=id%2Cname%2Cstatus%2Cpage%2Cquestions%2Cleads_count&limit=25&after=QVFIUlNTcWEyM00yRnIyejduakQzYkxZAUHJBZAHpkeFBVN2tkSnlrSlcxQXdBR3NOWjY1WEMwSHczczRfYkJORmZA4OElSUmVjb3BLZAExvS3I5ZA1A2dUFmWnhR'
      #           }
      # }

      def success?
        @success
      end
    end
  end
end
