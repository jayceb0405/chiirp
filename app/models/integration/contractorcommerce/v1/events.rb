# frozen_string_literal: true

# app/models/integration/contractorcommerce/v1/events.rb
module Integration
  module Contractorcommerce
    module V1
      module Events
        # Process lead type event
        # tt_model.update_credentials()
        #   (req) params:  (Hash) JSON body from Contractor Commerce API - https://api.contractorcommerce.com/api/documentation
        def process_lead_event(params:)
          # return unless @client_api_integration.events.is_a?(Array) && @client_api_integration.events.any?

          # @client_api_integration.events.each do |event|
          #   event.deep_symbolize_keys!

          #   # check that event matches params
          #   next unless event[:event_type] == 'lead' && event.dig(:criteria, :lead_types).is_a?(Array) && event.dig(:criteria, :lead_types).include?(params.dig(:leadType).downcase)

          #   contact = Contact.find_or_initialize_by_phone_or_email_or_ext_ref(
          #     client_id: @client_api_integration.client_id,
          #     phones:    { params.dig(:customer, :phone) => :mobile }
          #     # ext_refs:  { thumbtack: params.dig(:customer, :customerID) }
          #   )

          #   contact.raw_posts.create(ext_source: 'contractorcommerce', ext_id: params.dig(:customer, :customerID), data: params)

          #   contact.firstname = params.dig(:customer, :name).parse_name[:firstname]
          #   contact.lastname = params.dig(:customer, :name).parse_name[:lastname]
          #   contact.address1 = params.dig(:request, :location, :address1) if params.dig(:request, :location, :address1)
          #   contact.address2 = params.dig(:request, :location, :address2) if params.dig(:request, :location, :address2)
          #   contact.city = params.dig(:request, :location, :city) if params.dig(:request, :location, :city)
          #   contact.state = params.dig(:request, :location, :state) if params.dig(:request, :location, :state)
          #   contact.zipcode = params.dig(:request, :location, :zipCode) if params.dig(:request, :location, :zipCode)
          #   contact.save if contact.new_record? || contact.changed?

          #   ext_ref = contact.ext_references.find_or_initialize_by(target: 'contractorcommerce', ext_id: params.dig(:customer, :customerID))
          #   ext_ref.save if ext_ref.new_record?

          #   # add message to contact
          #   message = <<~MESSAGE
          #     Category: #{params.dig(:request, :category)}
          #     Title: #{params.dig(:request, :title)}

          #     #{params.dig(:request, :description)}

          #     Travel Preferences: #{params.dig(:request, :travelPreferences)}
          #     Schedule:
          #     #{params.dig(:request, :schedule).gsub('\n', "\n")}
          #   MESSAGE
          #   if params.dig(:request, :details).is_a?(Array) && params.dig(:request, :details).any?
          #     message += "\nDetails:\n"
          #     params.dig(:request, :details).each do |detail|
          #       message += "#{detail[:question]}: #{detail[:answer]}\n"
          #     end
          #   end

          #   if params.dig(:request, :attachments).is_a?(Array) && params.dig(:request, :attachments).any?
          #     message += "\nAttachments:\n"
          #     params.dig(:request, :attachments).each do |attachment|
          #       message += "#{attachment[:description]}: #{attachment[:url]}\n"
          #     end
          #   end

          #   contact.messages.create({
          #                             automated:  false,
          #                             from_phone: params.dig(:customer, :phone),
          #                             to_phone:   contact.user.default_from_twnumber&.phonenumber,
          #                             message:,
          #                             msg_type:   'textinother',
          #                             status:     'received'
          #                           })

          #   contact.process_actions(
          #     assign_user:       event.dig(:actions, :assign_user).to_bool,
          #     campaign_id:       event.dig(:actions, :campaign_id).to_i,
          #     group_id:          event.dig(:actions, :group_id).to_i,
          #     stage_id:          event.dig(:actions, :stage_id).to_i,
          #     tag_id:            event.dig(:actions, :tag_id).to_i,
          #     stop_campaign_ids: event.dig(:actions, :stop_campaign_ids)&.compact_blank
          #   )
        end

        def process_lead_update_event(params:); end

        def process_message_event(params:); end

        def process_review_event(params:); end
      end
    end
  end
end
