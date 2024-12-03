# frozen_string_literal: true

# app/lib/integrations/housecall_pro/parsers.rb
module Integrations
  module HousecallPro
    module Parsers
      # parse an incoming webhook and return a Hash
      # hcp_client.parse_webhook()
      #   (req) event:      (Hash)
      #   (opt) company_id: (String)
      def parse_webhook(args = {})
        reset_attributes

        if args.dig(:event).present?
          @result = {
            event:          args.dig(:event).to_s,
            company_id:     args.dig(:company_id).to_s,
            contact:        parse_contact_from_webhook(args),
            address:        parse_address_from_webhook(args),
            contact_phones: parse_phones_from_webhook(args),
            tags:           parse_tags_from_webhook(args),
            job:            parse_job_from_webhook(args),
            estimate:       parse_estimate_from_webhook(args),
            appointment:    parse_appointment_from_webhook(args),
            technician:     parse_technician_from_webhook(args)
          }
          @success    = true
        else
          @error_code = ''
          @message    = 'Unknown webhook event received.'
          @result     = {}
          @success    = false
        end

        @result
      end

      def parse_address_from_webhook(args = {})
        if args.dig(:job, :address)
          response = {
            id:          args.dig(:job, :address, :id).to_s,
            address_01:  args.dig(:job, :address, :street).to_s,
            address_02:  args.dig(:job, :address, :street_line_2).to_s,
            city:        args.dig(:job, :address, :city).to_s,
            state:       args.dig(:job, :address, :state).to_s,
            postal_code: args.dig(:job, :address, :zip).to_s,
            country:     args.dig(:job, :address, :country).to_s
          }
        elsif args.dig(:customer, :addresses)
          address  = args.dig(:customer, :addresses).first || {}
          response = {
            id:          address.dig(:id).to_s,
            address_01:  address.dig(:street).to_s,
            address_02:  address.dig(:street_line_2).to_s,
            city:        address.dig(:city).to_s,
            state:       address.dig(:state).to_s,
            postal_code: address.dig(:zip).to_s,
            country:     address.dig(:country).to_s
          }
        elsif args.dig(:estimate, :address)
          response = {
            id:          args.dig(:estimate, :address, :id).to_s,
            address_01:  args.dig(:estimate, :address, :street).to_s,
            address_02:  args.dig(:estimate, :address, :street_line_2).to_s,
            city:        args.dig(:estimate, :address, :city).to_s,
            state:       args.dig(:estimate, :address, :state).to_s,
            postal_code: args.dig(:estimate, :address, :zip).to_s,
            country:     args.dig(:estimate, :address, :country).to_s
          }
        else
          response = {
            id:          '',
            address_01:  '',
            address_02:  '',
            city:        '',
            state:       '',
            postal_code: '',
            country:     ''
          }
        end

        response
      end

      def parse_appointment_from_webhook(args = {})
        {
          id:                     args.dig(:appointment, :id).to_s,
          start_at:               args.dig(:appointment, :start_time).to_s,
          end_at:                 args.dig(:appointment, :end_time).to_s,
          arrival_window_minutes: args.dig(:appointment, :arrival_window_minutes).to_i
        }
      end

      def parse_contact_from_webhook(args = {})
        if args.dig(:job, :customer)
          {
            customer_id: args.dig(:job, :customer, :id).to_s,
            lastname:    args.dig(:job, :customer, :last_name).to_s,
            firstname:   args.dig(:job, :customer, :first_name).to_s,
            email:       args.dig(:job, :customer, :email).to_s,
            companyname: args.dig(:job, :customer, :company).to_s,
            lead_source: (args.dig(:job, :customer, :lead_source) || args.dig(:job, :lead_source)).to_s
            # HCP has a bug where the toggles for automations don’t always turn them off in HCP. So, their solution was to turn off all notifications in accounts that use Chiirp as well.
            # ok2text:     args.dig(:job, :customer, :notifications_enabled).to_bool ? 1 : 0,
            # ok2email:    args.dig(:job, :customer, :notifications_enabled).to_bool ? 1 : 0
          }
        elsif args.dig(:customer)
          {
            customer_id: args.dig(:customer, :id).to_s,
            lastname:    args.dig(:customer, :last_name).to_s,
            firstname:   args.dig(:customer, :first_name).to_s,
            email:       args.dig(:customer, :email).to_s,
            companyname: args.dig(:customer, :company).to_s,
            lead_source: (args.dig(:customer, :lead_source) || args.dig(:lead_source)).to_s
            # HCP has a bug where the toggles for automations don’t always turn them off in HCP. So, their solution was to turn off all notifications in accounts that use Chiirp as well.
            # ok2text:     args.dig(:customer, :notifications_enabled).to_bool ? 1 : 0,
            # ok2email:    args.dig(:customer, :notifications_enabled).to_bool ? 1 : 0
          }
        elsif args.dig(:estimate, :customer)
          {
            customer_id: args.dig(:estimate, :customer, :id).to_s,
            lastname:    args.dig(:estimate, :customer, :last_name).to_s,
            firstname:   args.dig(:estimate, :customer, :first_name).to_s,
            email:       args.dig(:estimate, :customer, :email).to_s,
            companyname: args.dig(:estimate, :customer, :company).to_s,
            lead_source: (args.dig(:estimate, :customer, :lead_source) || args.dig(:estimate, :lead_source)).to_s
            # HCP has a bug where the toggles for automations don’t always turn them off in HCP. So, their solution was to turn off all notifications in accounts that use Chiirp as well.
            # ok2text:     args.dig(:estimate, :customer, :notifications_enabled).to_bool ? 1 : 0,
            # ok2email:    args.dig(:estimate, :customer, :notifications_enabled).to_bool ? 1 : 0
          }
        else
          {
            customer_id: '',
            lastname:    '',
            firstname:   '',
            email:       '',
            companyname: '',
            lead_source: ''
            # ok2text:     '',
            # ok2email:    '',
          }
        end
      end

      def parse_estimate_from_webhook(args = {})
        response = {
          id:        args.dig(:estimate, :id).to_s,
          number:    args.dig(:estimate, :estimate_number).to_s,
          status:    args.dig(:estimate, :work_status).to_s,
          scheduled: {
            start_at:       args.dig(:estimate, :schedule, :scheduled_start).to_s,
            end_at:         args.dig(:estimate, :schedule, :scheduled_end).to_s,
            arrival_window: args.dig(:estimate, :schedule, :arrival_window).to_s
          },
          actual:    {
            started_at:   args.dig(:estimate, :work_timestamps, :started_at).to_s,
            completed_at: args.dig(:estimate, :work_timestamps, :completed_at).to_s,
            on_my_way_at: args.dig(:estimate, :work_timestamps, :on_my_way_at).to_s
          },
          options:   []
        }

        args.dig(:estimate, :options)&.each do |option|
          response[:options] << {
            id:              option.dig(:id).to_s,
            name:            option.dig(:name).to_s,
            option_number:   option.dig(:option_number).to_s,
            total_amount:    option.dig(:total_amount).to_s,
            approval_status: option.dig(:approval_status), # approved, pro approved, declined, pro declined, nil
            message:         option.dig(:message).to_s
          }
        end

        response
      end

      def parse_job_from_webhook(args = {})
        {
          id:                  (args.dig(:job, :id).presence || args.dig(:appointment, :job_id).presence).to_s,
          number:              args.dig(:job, :invoice_number).to_s,
          name:                args.dig(:job, :name).to_s,
          description:         args.dig(:job, :description).to_s,
          total_amount:        (args.dig(:job, :total_amount).to_i / 100.0).to_d,
          outstanding_balance: (args.dig(:job, :outstanding_balance).to_i / 100).to_d,
          status:              args.dig(:job, :work_status).to_s, # unscheduled, scheduled, in progress, completed
          scheduled:           {
            start_at:       args.dig(:job, :schedule, :scheduled_start).to_s,
            end_at:         args.dig(:job, :schedule, :scheduled_end).to_s,
            arrival_window: args.dig(:job, :schedule, :arrival_window).to_s
          },
          actual:              {
            started_at:   args.dig(:job, :work_timestamps, :started_at).to_s,
            completed_at: args.dig(:job, :work_timestamps, :completed_at).to_s,
            on_my_way_at: args.dig(:job, :work_timestamps, :on_my_way_at).to_s
          },
          notes:               args.dig(:job, :notes).to_s,
          invoice_number:      args.dig(:job, :invoice_number).to_s,
          original_estimate:   {
            id: args.dig(:job, :original_estimate_id).to_s
          }
        }
      end

      def parse_phones_from_webhook(args = {})
        response = if args.dig(:job, :customer)
                     [
                       [args.dig(:job, :customer, :mobile_number).to_s, 'mobile'],
                       [args.dig(:job, :customer, :home_number).to_s, 'home'],
                       [args.dig(:job, :customer, :work_number).to_s, 'work']
                     ]
                   elsif args.dig(:customer)
                     [
                       [args.dig(:customer, :mobile_number).to_s, 'mobile'],
                       [args.dig(:customer, :home_number).to_s, 'home'],
                       [args.dig(:customer, :work_number).to_s, 'work']
                     ]
                   elsif args.dig(:estimate, :customer)
                     [
                       [args.dig(:estimate, :customer, :mobile_number).to_s, 'mobile'],
                       [args.dig(:estimate, :customer, :home_number).to_s, 'home'],
                       [args.dig(:estimate, :customer, :work_number).to_s, 'work']
                     ]
                   else
                     []
                   end

        response.filter_map { |x| x[0].empty? ? nil : [x[0], x[1]] }.to_h
      end

      def parse_tags_from_webhook(args = {})
        tags = args.dig(:job, :tags).presence.to_a +
               args.dig(:job, :customer, :tags).presence.to_a +
               args.dig(:customer, :tags).presence.to_a +
               args.dig(:estimate, :customer, :tags).presence.to_a +
               args.dig(:estimate, :options)&.map { |t| t.dig(:tags) }&.flatten.presence.to_a

        tags.uniq
      end

      def parse_technician_from_webhook(args = {})
        response = {
          id:        '',
          firstname: '',
          lastname:  '',
          name:      '',
          email:     '',
          phone:     '',
          role:      ''
        }

        assigned_employees = args.dig(:job, :assigned_employees).presence || args.dig(:estimate, :assigned_employees).presence || args.dig(:appointment, :dispatched_employees).presence || []

        # role options: 'field tech', 'office staff', 'admin'
        employee = assigned_employees.find { |ae| ae[:role] == 'field tech' }
        employee = assigned_employees.find { |ae| ae[:role] == 'office staff' } if employee.blank?
        employee = assigned_employees.find { |ae| ae[:role] == 'admin' } if employee.blank?

        if employee.present?
          response = {
            id:        employee.dig(:id).to_s,
            firstname: employee.dig(:first_name).to_s,
            lastname:  employee.dig(:last_name).to_s,
            name:      "#{employee.dig(:first_name)} #{employee.dig(:last_name)}".strip,
            email:     employee.dig(:email).to_s,
            phone:     employee.dig(:mobile_number).to_s,
            role:      employee.dig(:role).to_s
          }
        end

        response
      end
    end
  end
end
