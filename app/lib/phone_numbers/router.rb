# frozen_string_literal: true

# app/lib/phone_numbers/router.rb
module PhoneNumbers
  module Router
    delegate :url_helpers, to: 'Rails.application.routes'

    # PhoneNumbers::Router.buy()
    #   (req) client_id:    (Integer)
    #   (req) client_name:  (String)
    #   (req) phone_number: (String)
    #   (req) phone_vendor: (String)
    #   (req) tenant:       (String)
    def self.buy(args = {})
      case args.dig(:phone_vendor).to_s
      when 'bandwidth'
        PhoneNumbers::Bandwidth.buy(args)
      when 'sinch'
        PhoneNumbers::SinchNumbers.new.buy(args)
      when 'twilio'
        PhoneNumbers::TwilioNumbers.buy(args)
      end
    end

    # PhoneNumbers::Router.delete_phone_number()
    #   (req) client_name:  (String)
    #   (req) phone_number: (String)
    #   (req) phone_vendor: (String)
    #   (req) vendor_id:    (String)
    def self.destroy(args = {})
      case args.dig(:phone_vendor).to_s
      when 'bandwidth'
        PhoneNumbers::Bandwidth.destroy(args)
      when 'sinch'
        PhoneNumbers::SinchNumbers.new.destroy(args)
      when 'twilio'
        PhoneNumbers::TwilioNumbers.destroy(args)
      end
    end

    # PhoneNumbers::Router.find()
    #   (req) area_code:    (String)
    #   (req) contains:     (String)
    #   (req) phone_vendor: (String)
    def self.find(args = {})
      case args.dig(:phone_vendor).to_s
      when 'bandwidth'
        PhoneNumbers::Bandwidth.find(args)
      when 'sinch'
        PhoneNumbers::SinchNumbers.new.available_numbers(args)
      when 'twilio'
        PhoneNumbers::TwilioNumbers.find(args)
      end
    end

    def self.status_update(order_id)
      PhoneNumbers::Bandwidth.status_update(order_id)
    end

    # look up a number to determine type, carrier, etc
    # PhoneNumbers::Router.lookup()
    #   (req) vendor:     (String)
    #   (req) phone:      (String)
    #   (opt) carrier:    (Boolean)
    #   (opt) phone_name: (Boolean)
    def self.lookup(args = {})
      vendor     = (args.dig(:vendor) || 'twilio').to_s
      phone      = args.dig(:phone).to_s
      carrier    = args.dig(:carrier).to_bool
      phone_name = args.dig(:phone_name).to_bool

      case vendor
      when 'bandwidth'
        response = PhoneNumbers::Bandwidth.lookup(phone:, carrier:, phone_name:)
      when 'sinch'
        response = PhoneNumbers::SinchNumbers.new.lookup(phone:, carrier:, phone_name:)
      when 'twilio'
        response = PhoneNumbers::TwilioNumbers.lookup(phone:, carrier:, phone_name:)
      end

      response
    end

    def self.subscription_callback(args = {})
      PhoneNumbers::Bandwidth.subscription_callback(args)
    end
  end
end
