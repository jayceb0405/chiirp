# frozen_string_literal: true

# app/controllers/integrations/servicetitan/contact_bookings_controller.rb
module Integrations
  module Servicetitan
    class ContactBookingsController < Servicetitan::IntegrationsController
      before_action :contact
      before_action :variables, only: :edit
      skip_before_action :authorize_user!, only: %i[edit update]

      # (GET) show Contact booking popup
      # /integrations/servicetitan/contact_bookings/:contact_id/edit
      # edit_integrations_servicetitan_contact_booking_path(:contact_id)
      # edit_integrations_servicetitan_contact_booking_url(:contact_id)
      def edit
        st_model  = Integration::Servicetitan::V2::Base.new(@client_api_integration)
        st_client = Integrations::ServiceTitan::Base.new(@client_api_integration.credentials)

        case params.dig(:commit).to_s.downcase
        when 'get_business_unit', 'refresh_business_units'
          st_model.refresh_business_units if params.dig(:commit).to_s.casecmp?('refresh_business_units')
          @servicetitan_business_units = st_model.business_units

          cards = %w[edit_business_unit]
        when 'get_availability'
          business_unit_id            = params.dig(:business_unit_id).to_i
          job_type_id                 = params.dig(:job_type_id).to_i
          ext_tech_id                 = params.dig(:ext_tech_id).to_i
          move                        = params.dig(:move).to_s.downcase
          @start_time                 = params.include?(:start_time) ? Chronic.parse(params[:start_time].to_s) : Time.current
          @business_unit_availability = []

          @start_time += 1.day if move == 'next'
          @start_time -= 1.day if move == 'previous'

          if business_unit_id.positive?
            st_client.technician_availability(business_unit_id:, job_type_id:, ext_tech_id:, time_zone: @contact.client.time_zone, start_time: @start_time, end_time: @start_time + 30.days)

            @business_unit_availability = st_client.result if st_client.success?
          end

          cards = %w[edit_availability]
        when 'get_campaigns', 'refresh_campaigns'
          st_model.refresh_campaigns if params.dig(:commit).to_s.casecmp?('refresh_campaigns')
          @servicetitan_campaigns = st_model.campaigns
          @client_api_integration_for_five9 = @client_api_integration.client.client_api_integrations.find_by(target: 'five9') if @client_api_integration.client.integrations_allowed.include?('five9')

          cards = %w[edit_campaign]
        when 'get_locations'
          st_client.locations(customer_id: @contact.ext_references.find_by(target: 'servicetitan')&.ext_id)

          @servicetitan_locations = if st_client.success?
                                      st_client.result.map { |lo| ["#{lo[:name]}, #{lo[:address][:street]}, #{lo[:address][:city]}, #{lo[:address][:state]} #{lo[:address][:zip]}", lo[:id]] }
                                    else
                                      []
                                    end

          cards = %w[show_locations]
        when 'get_locations_new'
          cards = %w[show_locations_new]
        when 'get_job_type', 'refresh_job_types'
          st_model.refresh_job_types if params.dig(:commit).to_s.casecmp?('refresh_job_types')
          @job_types = st_model.job_types

          cards = %w[edit_job_type]
        when 'get_technician', 'refresh_technicians'
          st_model.refresh_technicians if params.dig(:commit).to_s.casecmp?('refresh_technicians')
          @technicians = st_model.technicians(business_unit_id: params.dig(:business_unit_id).to_i, for_select: true).presence || st_model.technicians(for_select: true)

          cards = %w[edit_technician]
        when 'get_tag_type', 'refresh_tag_types'
          st_model.refresh_tag_types if params.dig(:commit).to_s.casecmp?('refresh_tag_types')
          @tag_types = st_model.tag_types

          cards = %w[edit_tag_type]
        else
          cards = %w[show_booking_modal]
        end

        render partial: 'integrations/servicetitan/js/show', locals: { cards: }
      end

      # (PUT/PATCH) save a Contact Booking
      # /integrations/servicetitan/contact_bookings/:contact_id
      # integrations_servicetitan_contact_booking_path(:contact_id)
      # integrations_servicetitan_contact_booking_url(:contact_id)
      def update
        sanitized_params = params_update
        business_unit_id = sanitized_params.dig(:business_unit_id).to_s
        campaign_id      = sanitized_params.dig(:campaign_id).to_s
        customer_id      = ''
        description      = sanitized_params.dig(:description).to_s
        job_type_id      = sanitized_params.dig(:job_type_id).to_s
        location_id      = sanitized_params.dig(:location_id).to_s
        tag_type_names   = [sanitized_params.dig(:tag_type_names) || []].flatten.compact_blank
        ext_tech_id      = sanitized_params.dig(:ext_tech_id).to_s
        time_slot        = sanitized_params.dig(:time_slot).to_s.split('|')
        st_client        = Integrations::ServiceTitan::Base.new(@client_api_integration.credentials)

        if time_slot.length == 2
          start_time = Time.use_zone(@client_api_integration.client.time_zone) { Chronic.parse(time_slot[0]) }.utc
          end_time   = Time.use_zone(@client_api_integration.client.time_zone) { Chronic.parse(time_slot[1]) }.utc
        else
          start_time = nil
          end_time   = nil
        end

        custom_fields              = {}
        all_custom_fields_received = true
        use_values                 = %w[req inc]

        @client_api_integration.booking_fields.select { |_key, values| use_values.include?(values['use'].to_s) && values['client_custom_field_id'].to_i.positive? }.each do |st_custom_field_id, values|
          custom_fields[st_custom_field_id] = values
          custom_fields[st_custom_field_id]['value'] = params.dig(:client_custom_fields, values['client_custom_field_id'].to_s)
          all_custom_fields_received = false if values['use'].to_s == 'req' && params.dig(:client_custom_fields, values['client_custom_field_id'].to_s).blank?
        end

        if business_unit_id.present? && job_type_id.present? && campaign_id.present? && location_id.present? && tag_type_names.present? && start_time && end_time && all_custom_fields_received

          if (customer_id = @contact.ext_references.find_by(target: 'servicetitan')&.ext_id).present?
            st_client.update_customer(
              customer_id:,
              firstname:     @contact.firstname,
              lastname:      @contact.lastname,
              address1:      @contact.address1,
              address2:      @contact.address2,
              city:          @contact.city,
              state:         @contact.state,
              zipcode:       @contact.zipcode,
              email:         @contact.email,
              ok2email:      @contact.ok2email.to_i == 1,
              phone_numbers: @contact.contact_phones.pluck(:label, :phone),
              custom_fields:
            )

            if st_client.success?

              if location_id == '-1'
                st_client.add_location(
                  customer_id:,
                  firstname:     @contact.firstname,
                  lastname:      @contact.lastname,
                  address_01:    params.dig(:address1).to_s,
                  address_02:    params.dig(:address2).to_s,
                  city:          params.dig(:city).to_s,
                  state:         params.dig(:state).to_s,
                  postal_code:   params.dig(:zipcode).to_s,
                  phone_numbers: [['phone', params.dig(:phone).to_s], ['phone', params.dig(:alt_phone).to_s]]
                )

                if st_client.success?
                  location_id = st_client.result
                else
                  sweetalert_error('Oops...', "Job posting was NOT successful for #{@contact.fullname}. Location could not be added. (Error: #{st_client.result[:error_message]})", '', { persistent: 'Ok' })
                end
              end
            else
              sweetalert_error('Oops...', "Job posting was NOT successful for #{@contact.fullname}. Customer could not be updated. (Error: #{st_client.result[:error_message]})", '', { persistent: 'Ok' })
            end
          else
            st_client.new_customer(
              firstname:     @contact.firstname,
              lastname:      @contact.lastname,
              address_01:    @contact.address1,
              address_02:    @contact.address2,
              city:          @contact.city,
              state:         @contact.state,
              postal_code:   @contact.zipcode,
              email:         @contact.email,
              ok2email:      @contact.ok2email.to_i == 1,
              phone_numbers: @contact.contact_phones.pluck(:label, :phone),
              custom_fields:
            )

            if st_client.success?
              customer_id = st_client.result.dig(:customer_id).to_s
              @contact.ext_references.create(target: 'servicetitan', ext_id: customer_id) unless customer_id.to_i.zero?
              location_id = st_client.result.dig(:location_id).to_s
            else
              sweetalert_error('Oops...', "Job posting was NOT successful for #{@contact.fullname}. Customer could not be added. (Error: #{st_client.message})", '', { persistent: 'Ok' })
            end
          end

          if customer_id.present?
            st_client.create_job(
              business_unit_id:,
              job_type_id:,
              ext_tech_id:,
              campaign_id:,
              customer_id:,
              location_id:,
              tag_names:        tag_type_names,
              start_time:,
              end_time:,
              description:,
              custom_fields:
            )

            if st_client.success?
              if st_client.result.to_i.positive?
                @contact.send_to_five9(action: 'book')

                phone_number = RedisCloud.redis.get("contact:#{@contact.id}:five9_incoming_phone")

                if phone_number.present?
                  Integration::Servicetitan::V2::Base.new(@client_api_integration).delay(
                    priority:   DelayedJob.job_priority('servicetitan_update_call'),
                    queue:      DelayedJob.job_queue('servicetitan_update_call'),
                    contact_id: @contact.id,
                    user_id:    @contact.user_id,
                    process:    'servicetitan_update_call',
                    data:       { contact_id: @contact_id, phone_number:, booked_at: Time.current }
                  ).update_call_type(
                    contact_id:   @contact_id,
                    phone_number:,
                    booked_at:    Time.current,
                    call_type:    'Booked'
                  )
                end

                sweetalert_success('Congratulations!', "Job posted successfully for #{@contact.fullname}. (Job ID: #{st_client.result})", '', { persistent: 'Ok' })
              else
                sweetalert_error('Oops...', "Job posting was NOT successful for #{@contact.fullname}. Job ID unknown. (Error: #{st_client.message})", '', { persistent: 'Ok' })
              end
            else
              sweetalert_error('Oops...', "Job posting was NOT successful for #{@contact.fullname}. (Error: #{st_client.message})", '', { persistent: 'Ok' })
            end
          end
        else
          sweetalert_error('Oops...', "Job posting was NOT successful for #{@contact.fullname}. (Error: Incomplete data)", '', { persistent: 'Ok' })
        end

        render partial: 'integrations/servicetitan/js/show', locals: { cards: %w[contact_bookings_update] }
      end

      private

      def params_update
        params.permit(:business_unit_id, :job_type_id, :ext_tech_id, :campaign_id, :time_slot, :location_id, :description, tag_type_names: [])
      end

      def variables
        @business_unit_id = params[:business_unit_id].to_i
        @job_type_id      = params[:job_type_id].to_i
        @campaign_id      = params[:campaign_id].to_i
        @technician_ids   = params[:technician_ids] || []
        @tag_type_names   = params[:tag_type_names] || []
        @field_name       = params[:field_name]
        @form_type        = params[:form_type] || 'message_central'
      end
    end
  end
end
