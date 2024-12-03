# frozen_string_literal: true

# app/models/Integration/facebook/leads.rb
module Integration
  module Facebook
    module Leads
      # get a Facebook lead from a Facebook page
      # fb_model.page_lead()
      # Integration::Facebook::Base.new(user_api_integration).page_lead()
      #   (req) page_token: (String)
      #   (req) lead_id:    (String)
      def page_lead(**args)
        reset_attributes

        @fb_client.page_lead(page_token: args.dig(:page_token), lead_id: args.dig(:lead_id))
        update_attributes_from_client

        if success?
          @result = @fb_client.result

          @fb_client.result.dig(:field_data).each do |field_data|
            @result[field_data[:name].to_sym] = field_data[:values].first.to_s if field_data.include?(:name) && field_data.include?(:values)
          end

          @result.delete(:field_data)

          @success  = true
        else
          @result = {}
        end

        @result
      end

      # get forms for a Facebook Page
      # fb_model.page_lead_forms()
      # Integrations::Facebook::Base.new(user_api_integration).page_lead_forms()
      #   (req) page_id: (String)
      def page_lead_forms(**args)
        reset_attributes

        if args.dig(:page_id).blank?
          @message = 'Facebook Page ID is required'
          return []
        elsif (fb_page = @user_api_integration.pages.find { |p| p['id'] == args[:page_id].to_s }).nil?
          @message = 'Facebook Page not found'
          return []
        end

        @fb_client.page_lead_forms(page_token: fb_page['token'], page_id: fb_page['id'])
        update_attributes_from_client

        if success?
          @result   = @fb_client.result.dig(:data)
          @success  = true
        else
          @result = []
        end

        @result
      end
      # example response
      # [
      #   { id:          '475035917572894',
      #     name:        '2022 Special Offer',
      #     status:      'ACTIVE',
      #     page:        { name: 'Chiirp', id: '298964710698004' },
      #     questions:   [{ key: 'what_kind_of_business_are_you_in?_', label: 'What kind of business are you in?', type: 'CUSTOM', id: '487563962717667' },
      #                   { key: 'full_name', label: 'Full name', type: 'FULL_NAME', id: '448949863369085' },
      #                   { key: 'email', label: 'Email', type: 'EMAIL', id: '1948430065329831' },
      #                   { key: 'phone_number', label: 'Phone number', type: 'PHONE', id: '667505857745568' }],
      #     leads_count: 0 },
      #   { id:          '355436802643565',
      #     name:        'Improve Your Communication - Double Your Sales',
      #     status:      'ACTIVE',
      #     page:        { name: 'Chiirp', id: '298964710698004' },
      #     questions:   [{ key: 'email', label: 'Email', type: 'EMAIL', id: '509411336989953' },
      #                   { key: 'full_name', label: 'Full name', type: 'FULL_NAME', id: '956800921781940' },
      #                   { key: 'phone_number', label: 'Phone number', type: 'PHONE', id: '152440090313334' }],
      #     leads_count: 0 },
      #   { id:          '481619243165427',
      #     name:        'What kind of business survey',
      #     status:      'ACTIVE',
      #     page:        { name: 'Chiirp', id: '298964710698004' },
      #     questions:   [{ key:     'are_you_currently_running_ads_for_your_business?_',
      #                     label:   'Are you currently running ads for your business?',
      #                     options: [{ key: 'yes', value: 'Yes' }, { key: 'no', value: 'No' }],
      #                     type:    'CUSTOM',
      #                     id:      '976820606190971' },
      #                   { key:     'how_many_employees_at_your_company?_',
      #                     label:   'How many employees at your company?',
      #                     options: [{ key: '1-5', value: '1-5' }, { key: '6-10', value: '6-10' }, { key: '11-50', value: '11-50' }, { key: '50+', value: '50+' }],
      #                     type:    'CUSTOM',
      #                     id:      '4148194511897449' },
      #                   { key:     'would_you_be_willing_to_jump_on_a_quick_10_minute_demo_to_see_how_this_all_works?_',
      #                     label:   'Would you be willing to jump on a quick 10 minute demo to see how this all works?',
      #                     options: [{ key: 'yes', value: 'Yes' }, { key: 'no', value: 'No' }],
      #                     type:    'CUSTOM',
      #                     id:      '983851719028117' },
      #                   { key: 'what_kind_of_business_are_you_in?_', label: 'What kind of business are you in?', type: 'CUSTOM', id: '2870422593203305' },
      #                   { key: 'email', label: 'Email', type: 'EMAIL', id: '749793719053688' },
      #                   { key: 'full_name', label: 'Full name', type: 'FULL_NAME', id: '271809734621737' },
      #                   { key: 'phone_number', label: 'Phone number', type: 'PHONE', id: '2818628395118959' }],
      #     leads_count: 0 }, ...
      # ]
    end
  end
end
