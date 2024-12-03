# frozen_string_literal: true

# app/lib/integrations/responsi_bid.rb
module Integrations
  # process various API calls to ResponsiBid
  class ResponsiBid
    attr_reader :error, :message, :result

    # initialize Integrations::ResponsiBid object
    # rb_client = Integrations::ResponsiBid.new()
    def initialize
      reset_attributes
      @result = nil
    end

    # parse & normalize data from webhook
    # rb_client.parse_webhook(params)
    def parse_webhook(args = {})
      @success = true

      {
        event_status:             args.dig(:CompanyBid, :status).to_s.downcase,
        contact:                  parse_contact_from_webhook(args),
        scheduled_start_at:       Chronic.parse("#{args.dig(:CompanyBid, :booking_date)} #{args.dig(:CompanyBid, :booking_arrival_start_time)}"),
        scheduled_end_at:         args.dig(:CompanyBid, :booking_date).present? ? Chronic.parse("#{args.dig(:CompanyBid, :booking_date)} #{args.dig(:CompanyBid, :booking_arrival_start_time)}") + args.dig(:CompanyBid, :job_duration_hours).to_i.hours + args.dig(:CompanyBid, :job_duration_minutes).to_i.minutes : nil,
        scheduled_arrival_window: args.dig(:CompanyBid, :booking_date).present? ? ((Chronic.parse("#{args.dig(:CompanyBid, :booking_date)} #{args.dig(:CompanyBid, :booking_arrival_end_time)}") - Chronic.parse("#{args.dig(:CompanyBid, :booking_date)} #{args.dig(:CompanyBid, :booking_arrival_start_time)}")).to_d / 60).round : nil,
        notes:                    args.dig(:CompanyBid, :notes).to_s,
        residential:              args.dig(:CompanyBid, :commercial).to_i.zero?,
        commercial:               args.dig(:CompanyBid, :commercial).to_i.positive?,
        proposal_url:             args.dig(:CompanyBid, :proposal_url).to_s
      }
    end

    def success?
      @success
    end

    private

    # parse/normalize Contact data from webhook
    def parse_contact_from_webhook(args = {})
      response = {
        ext_id:              args.dig(:Contact, :id).to_s,
        firstname:           args.dig(:Contact, :first_name).to_s,
        lastname:            args.dig(:Contact, :last_name).to_s,
        address_01:          args.dig(:Contact, :street1).to_s,
        address_02:          args.dig(:Contact, :street2).to_s,
        city:                args.dig(:Contact, :service_area).to_s.split(',').first&.strip.to_s,
        state:               args.dig(:Contact, :service_area).to_s.split(',').last&.strip.to_s,
        zipcode:             args.dig(:Contact, :zip).to_s,
        email:               args.dig(:Contact, :email).to_s,
        opt_out:             args.dig(:Contact, :opt_out).to_bool,
        explicit_opt_in:     args.dig(:Contact, :explicit_opt_in).to_bool,
        explicit_sms_opt_in: args.dig(:Contact, :explicit_sms_opt_in).to_bool,
        lead_source:         args.dig(:Contact, :lead_source).to_s,
        service_area:        args.dig(:Contact, :service_area).to_s,
        phones:              {}
      }

      response[:phones][args.dig(:Contact, :phone1).to_s] = 'mobile' if args.dig(:Contact, :phone1).present?
      response[:phones][args.dig(:Contact, :phone2).to_s] = 'home' if args.dig(:Contact, :phone2).present?

      response
    end

    def reset_attributes
      @error       = 0
      @message     = ''
      @success     = false
    end
  end
end
