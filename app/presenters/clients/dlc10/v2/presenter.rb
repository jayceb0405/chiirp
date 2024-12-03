# frozen_string_literal: true

# app/presenters/clients/dlc10/v2/presenter.rb
module Clients
  module Dlc10
    module V2
      class Presenter
        attr_accessor :user
        attr_reader :client, :dlc10_campaign, :phone_number

        # Clients::Dlc10::V2::Presenter.new(client: @client)
        def initialize(args = {})
          self.client   = args.dig(:client)
          @dlc10_client = ::Dlc10::CampaignRegistry::V2::Base.new
        end

        def brand_feedback
          if dlc10_brand_verified? || !dlc10_brand_submitted?
            ''
          else
            feedback = @client.dlc10_brand.feedback
            JsonLog.info 'Clients::Dlc10::V2::Presenter.brand_feedback', { feedback: }

            if feedback.present?
              response = '<ul>'

              feedback.each do |f|
                response += "<li>#{f}</li>"
              end

              response += '</ul>'
            else
              ''
            end
          end
        end

        def brand_submit_buttons
          response = []
          response << { id: 'save_brand_submit_button', title: 'Save brand & submit to TCR', disable_with: 'Saving & submitting brand' } if @client.dlc10_brand.tcr_brand_id.blank?
          response << { id: 'save_brand_resubmit_button', title: 'Save brand & re-submit to TCR', disable_with: 'Saving & re-submitting brand' } if @client.dlc10_brand.tcr_brand_id.present?
          response << { id: 'save_brand', title: 'Save brand', disable_with: 'Saving brand' }
        end

        def campaign_index_colspan
          @client.dlc10_charged ? 9 : 8
        end

        def client=(client)
          @client = case client
                    when Client
                      client
                    when Integer
                      Client.find_by(id: client)
                    else
                      Client.new
                    end

          @dlc10_brand_special_fields         = %w[ein ein_country entity_type company_name]
          @dlc10_brand_special_fields_ok2edit = nil
          @dlc10_brand_verified               = nil
          @dlc10_campaign                     = nil
          @dlc10_campaign_verified            = nil
          @dlc10_qualified_campaign_types     = nil
          @phone_number                       = nil
        end

        def campaign_edit_submit_buttons(current_user, session)
          response  = []
          response << { title: 'Save Use Case & Submit to TCR', disable_with: 'Saving & Submitting Use Case' } unless dlc10_campaign_verified?
          response << { title: 'Save Use Case & Re-Submit to Phone Vendor', disable_with: 'Saving & Re-Submitting Use Case to Phone Vendor' } if dlc10_campaign_verified? && @dlc10_campaign&.dca_completed_at.blank? && (current_user.team_member? || current_user.agency_user_logged_in_as(session)&.team_member?)
          response << { title: 'Save Use Case', disable_with: 'Saving Use Case' }
        end

        def dlc10_brand_resubmitted?
          !dlc10_brand_verified? && @client.dlc10_brand&.resubmitted_at.present?
        end

        def dlc10_brand_submitted?
          @client.dlc10_brand&.submitted_at.present?
        end

        def dlc10_brand_verified?
          @dlc10_brand_verified = @dlc10_brand_verified.nil? ? @client.dlc10_brand&.verified? : @dlc10_brand_verified
        end

        def dlc10_brand_verification_notice
          if dlc10_brand_verified?
            "<i class=\"fa fa-check text-success mr-2\"></i>Brand was approved #{Friendly.new.date(@client.dlc10_brand.verified_at, @client.time_zone, false)}."
          elsif dlc10_brand_resubmitted?
            "<i class=\"fa fa-times text-danger mr-2\"></i>Brand was resubmitted #{Friendly.new.date(@client.dlc10_brand.resubmitted_at, @client.time_zone, false)}."
          elsif dlc10_brand_submitted?
            "<i class=\"fa fa-times text-danger mr-2\"></i>Brand was submitted #{Friendly.new.date(@client.dlc10_brand.submitted_at, @client.time_zone, false)}."
          else
            '<i class="fa fa-times text-danger mr-2"></i>Brand has NOT been submitted.'
          end
        end

        def dlc10_campaign=(dlc10_campaign)
          @dlc10_campaign = case dlc10_campaign
                            when Clients::Dlc10::Campaign
                              dlc10_campaign
                            when Integer
                              Clients::Dlc10::Campaign.find_by(id: dlc10_campaign)
                            else
                              @client.dlc10_brand.campaigns.new
                            end
        end

        def dlc10_campaign_phone_vendor_verified?(dlc10_registration_id)
          Clients::Dlc10::Registration.find_by(id: dlc10_registration_id)&.shared_at.present?
        end

        def dlc10_campaign_verified?
          @dlc10_campaign_verified ||= @dlc10_campaign&.verified?
        end

        def dlc10_campaign_use_case_count(min, max)
          if min.zero?
            '0'
          elsif min == max
            min.to_s
          else
            "#{min} - #{max}"
          end
        end

        def dlc10_campaign_use_case_throughput(scope, tpm, dailycap)
          if scope.to_s.casecmp?('campaign')
            "#{tpm}/use case/minute"
          elsif scope.to_s.casecmp?('phone_number')
            "#{tpm}/phone number/minute"
          elsif dailycap.to_i.positive?
            "#{dailycap}/brand/day"
          else
            'Undefined'
          end
        end

        def dlc10_campaigns
          self.client.dlc10_brand.campaigns.order(:use_case, :vertical, :created_at)
        end

        def dlc10_ok_to_edit(user)
          !self.client.new_record? && user.access_controller?('clients', 'dlc10')
        end

        def dlc10_phone_numbers
          @client.twnumbers.where(phone_vendor: %w[bandwidth sinch])
        end

        def dlc10_qualified_campaign_types
          @dlc10_qualified_campaign_types ||= @dlc10_client.qualified_campaign_types(@client.dlc10_brand.tcr_brand_id)
        end

        def ok2edit_brand_field?(field_name)
          if @dlc10_brand_special_fields.include?(field_name)
            @dlc10_brand_special_fields_ok2edit = @dlc10_brand_special_fields_ok2edit.nil? ? @client.dlc10_brand.ok2edit_brand_field?(field_name) : @dlc10_brand_special_fields_ok2edit
          else
            @client.dlc10_brand.ok2edit_brand_field?(field_name)
          end
        end

        def options_for_brand_alt_business_id_type
          @dlc10_client.brand_alt_business_id_types
        end

        def options_for_brand_entity_type
          [['Private Company', 'PRIVATE_PROFIT'], ['Public Company', 'PUBLIC_PROFIT'], ['Non-Profit Company', 'NON_PROFIT'], %w[Government GOVERNMENT]]
        end

        def options_for_brand_stock_exchange
          @dlc10_client.brand_stock_exchanges
        end

        def options_for_brand_verticals
          @dlc10_client.brand_verticals.map { |key, value| [value.dig(:displayName), key] }
        end

        def options_for_dlc10_campaigns
          self.client.dlc10_brand.campaigns.where.not(tcr_campaign_id: nil).where.not(dca_completed_at: nil).order(:use_case, :vertical, :created_at).pluck(:name, :id).uniq
        end

        def options_for_dlc10_sub_use_cases
          @dlc10_client.valid_sub_use_cases.keys.map(&:to_s).map { |u| [u == '2FA' ? u : u.titleize, u] }
        end

        def options_for_dlc10_use_case
          dlc10_qualified_campaign_types.map { |c| [c[:usecase].to_s == '2FA' ? c[:usecase].to_s : c[:usecase].to_s.titleize, c[:usecase].to_s] }
        end

        def campaign_accepted_at
          Friendly.new.date(@dlc10_campaign&.accepted_at, @client.time_zone, false)
        end

        def campaign_dca_completed_at
          Friendly.new.date(@dlc10_campaign&.dca_completed_at, @client.time_zone, false)
        end

        def campaign_required_sample_count
          ((dlc10_qualified_campaign_types.find { |u| u[:usecase] == @dlc10_campaign&.use_case.to_s } || {}).dig(:mnoMetadata)&.map { |_mno, values| values.dig(:minMsgSamples).to_i } || []).max.to_i
        end

        def campaign_required_samples
          response = []
          campaign_required_sample_count.times { |i| response << "sample#{i + 1}" }

          response[0..4]
        end

        def campaign_shared_at
          Friendly.new.date(@dlc10_campaign&.shared_at, @client.time_zone, false)
        end

        def max_sub_use_cases
          (dlc10_qualified_campaign_types.find { |t| t[:usecase] == @dlc10_campaign&.use_case.to_s } || {}).dig(:maxSubUsecases).to_i
        end

        def min_sub_use_cases
          (dlc10_qualified_campaign_types.find { |t| t[:usecase] == @dlc10_campaign&.use_case.to_s } || {}).dig(:minSubUsecases).to_i
        end

        def phone_number_locked
          @phone_number.dlc10_campaign_id.to_i.positive? && @dlc10_campaign&.shared_at.present? && @dlc10_campaign&.accepted_at.present?
        end

        def phone_number=(phone_number)
          @phone_number = case phone_number
                          when Twnumber
                            phone_number
                          when Integer
                            @client.twnumbers.find_by(id: phone_number)
                          else
                            @client.twnumbers.new
                          end

          @dlc10_campaign = phone_number.dlc10_campaign
        end
      end
    end
  end
end
