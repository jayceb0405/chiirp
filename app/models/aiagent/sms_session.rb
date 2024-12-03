# frozen_string_literal: true

# app/models/aiagent/sms_session.rb
class Aiagent
  class SmsSession < Session
    def respond_with(content)
      self.contact.send_text(
        automated:          true,
        content:            "#{aiagent&.show_ai ? 'AI: ' : ''}#{content}",
        aiagent_session_id: self.id,
        msg_type:           :textoutaiagent,
        to_phone:           self.last_phone_used,
        from_phone:         self.from_phone
      )
    end

    private

    def conversation_ended_with_function
      self.contact.process_actions(
        campaign_id:       self.aiagent.campaign_id,
        stop_campaign_ids: self.aiagent.stop_campaign_ids,
        group_id:          self.aiagent.group_id,
        stage_id:          self.aiagent.stage_id,
        tag_id:            self.aiagent.tag_id
      )
    end

    def conversation_ended_with_help
      self.contact.process_actions(
        campaign_id:       self.aiagent.help_campaign_id,
        stop_campaign_ids: self.aiagent.help_stop_campaign_ids,
        group_id:          self.aiagent.help_group_id,
        stage_id:          self.aiagent.help_stage_id,
        tag_id:            self.aiagent.help_tag_id
      )
    end

    def conversation_ended_with_session_length
      self.contact.process_actions(
        campaign_id:       self.aiagent.session_length_campaign_id,
        stop_campaign_ids: self.aiagent.session_length_stop_campaign_ids,
        group_id:          self.aiagent.session_length_group_id,
        stage_id:          self.aiagent.session_length_stage_id,
        tag_id:            self.aiagent.session_length_tag_id
      )
    end

    def save_extract_data(args)
      # copied from app/controllers/api/v3/clients/widgets_controller.rb:105 - Api::V3::Clients::WidgetsController#save_contact
      args[:birthdate] = Chronic.parse(args[:birthdate]) if args.include?(:birthdate)
      args[:email]     = args.dig(:email).to_s if args.include?(:email)

      contact.update(
        lastname:  (args.dig(:lastname) || contact.lastname).to_s,
        firstname: (args.dig(:firstname) || contact.firstname).to_s,
        email:     (args.dig(:email) || contact.email).to_s,
        address1:  (args.dig(:address1) || contact.address1).to_s,
        address2:  (args.dig(:address2) || contact.address2).to_s,
        city:      args.dig(:city) || contact.city.to_s,
        state:     args.dig(:state) || contact.state.to_s,
        zipcode:   args.dig(:zipcode) || contact.zipcode.to_s,
        birthdate: args.dig(:birthdate) || contact.birthdate,
        ok2text:   1,
        ok2email:  1,
        sleep:     false
      )

      general_form_fields = ::Webhook.internal_key_hash(client, 'contact', %w[personal ext_references]).keys.map(&:to_sym) + %i[notes user_id sleep block ok2text ok2email]
      other_fields = ::Webhook.internal_key_hash(client, 'contact', %w[phones]).keys.map(&:to_sym)
      allowed_fields = args.map { |name, _| name.to_sym } - general_form_fields - other_fields
      contact.update_custom_fields(custom_fields: args.keep_if { |name, _| allowed_fields.include?(name.to_sym) })
    end

    # book an appointment with ServiceTitan
    # paramaters:
    #   (req) start_time String
    #   (req) end_time String
    #   (req) location_id String
    #   (req) technician_id String
    #   (req) customer_id String
    def st_book_appointment(params = {})
      st_client.create_job(
        business_unit_id: self.aiagent.business_unit_id.to_s,
        job_type_id:      self.aiagent.job_type_id.to_s,
        ext_tech_id:      params[:technician_id].to_s,
        campaign_id:      self.aiagent.st_campaign_id.to_s,
        customer_id:      params[:customer_id].to_s,
        location_id:      params[:location_id].to_s,
        tag_names:        self.aiagent.tag_type_names,
        start_time:       params[:start_time],
        end_time:         params[:end_time],
        description:      self.aiagent.description.to_s,
        custom_fields:    self.aiagent.client_custom_fields
      )

      raise "Job posting was NOT successful for #{self.contact.fullname}. (Error: #{st_client.message})" unless st_client.success?
      raise "Job posting was NOT successful for #{self.contact.fullname}. Job ID unknown. (Error: #{st_client.message})" unless st_client.result.to_i.positive?

      self.contact.send_to_five9(action: 'book')

      # phone_number = RedisCloud.redis.get("contact:#{self.contact.id}:five9_incoming_phone")

      # return unless phone_number.present?

      # Integration::Servicetitan::V2::Base.new(@client_api_integration).delay(
      #   priority:   DelayedJob.job_priority('servicetitan_update_call'),
      #   queue:      DelayedJob.job_queue('servicetitan_update_call'),
      #   contact_id: self.contact.id,
      #   user_id:    self.contact.user_id,
      #   process:    'servicetitan_update_call',
      #   data:       { contact_id: self.contact_id, phone_number:, booked_at: Time.current }
      # ).update_call_type(
      #   contact_id:   self.contact_id,
      #   phone_number:,
      #   booked_at:    Time.current,
      #   call_type:    'Booked'
      # )
    end

    # save customer data and get customer_id and location_id in return
    # paramaters:
    #   (req) address1 String
    #   (req) address2 String
    #   (req) city String
    #   (req) state String
    #   (req) zipcode String
    def st_customer_data(params = {})
      location_id = params.dig(:location_id).to_s
      use_values  = %w[req inc]

      custom_fields = {}
      client_api_integration.booking_fields.select { |_key, values| use_values.include?(values['use'].to_s) && values['client_custom_field_id'].to_i.positive? }.each do |st_custom_field_id, values|
        custom_fields[st_custom_field_id.to_i] = values
        custom_fields[st_custom_field_id.to_i]['value'] = self.aiagent.client_custom_fields[values['client_custom_field_id'].to_s]
      end

      if (customer_id = self.contact.ext_references.find_by(target: 'servicetitan')&.ext_id).present?
        st_client.update_customer(
          customer_id:,
          firstname:     self.contact.firstname,
          lastname:      self.contact.lastname,
          address1:      self.contact.address1,
          address2:      self.contact.address2,
          city:          self.contact.city,
          state:         self.contact.state,
          zipcode:       self.contact.zipcode,
          email:         self.contact.email,
          ok2email:      self.contact.ok2email.to_i == 1,
          phone_numbers: self.contact.contact_phones.pluck(:label, :phone),
          custom_fields:
        )

        raise "Job posting was NOT successful for #{self.contact.fullname}. Customer could not be updated. (Error: #{st_client.message})" unless st_client.success?

        if location_id.blank?
          st_client.add_location(
            customer_id:,
            firstname:     self.contact.firstname,
            lastname:      self.contact.lastname,
            address1:      params.dig(:address1).to_s,
            address2:      params.dig(:address2).to_s,
            city:          params.dig(:city).to_s,
            state:         params.dig(:state).to_s,
            zipcode:       params.dig(:zipcode).to_s,
            phone_numbers: self.contact.contact_phones.pluck(:label, :phone)
          )

          raise "Job posting was NOT successful for #{self.contact.fullname}. Location could not be added. (Error: #{st_client.message})" unless st_client.success?

          location_id = st_client.result
        end

      else
        st_client.new_customer(
          firstname:     self.contact.firstname,
          lastname:      self.contact.lastname,
          address1:      params.dig(:address1).to_s,
          address2:      params.dig(:address2).to_s,
          city:          params.dig(:city).to_s,
          state:         params.dig(:state).to_s,
          zipcode:       params.dig(:zipcode).to_s,
          email:         self.contact.email,
          ok2email:      self.contact.ok2email.to_i == 1,
          phone_numbers: self.contact.contact_phones.pluck(:label, :phone),
          custom_fields:
        )

        raise "Job posting was NOT successful for #{self.contact.fullname}. Customer could not be added. (Error: #{st_client.message})" unless st_client.success?

        customer_id = st_client.result.dig(:customer_id).to_s
        self.contact.ext_references.create(target: 'servicetitan', ext_id: customer_id)
        location_id = st_client.result.dig(:location_id).to_s
      end

      [customer_id, location_id]
    end
  end
end
