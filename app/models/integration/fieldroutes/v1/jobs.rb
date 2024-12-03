# frozen_string_literal: true

# app/models/integration/fieldroutes/v1/jobs.rb
module Integration
  module Fieldroutes
    module V1
      module Jobs
        # find or create a Contacts::Job based on incoming webhook data
        def job(contact, **args)
          return false unless contact.is_a?(Contact) && args.dig(:appointmentID).present? && args.dig(:customerID).present? &&
                              (contact_job = contact.jobs.find_or_initialize_by(ext_source: 'fieldroutes', ext_id: args[:appointmentID])).present?

          # start_date_updated = Chronic.parse(args.dig(:startAt)) != contact_job.scheduled_start_at
          # tech_updated       = args.dig(:visitSchedule, :assignedTo, :nodes)&.first&.dig(:id) != contact_job.ext_tech_id

          contact_job.update(
            description:        (args.dig(:description).presence || contact_job.description).to_s,
            job_type:           (args.dig(:serviceType).presence || contact_job.job_type).to_s,
            address_01:         (args.dig(:address).presence || contact_job.address_01).to_s,
            city:               (args.dig(:city).presence || contact_job.city).to_s,
            state:              (args.dig(:state).presence || contact_job.state).to_s,
            postal_code:        (args.dig(:zip).presence || contact_job.postal_code).to_s,
            scheduled_start_at: scheduled_start_at_from_webhook(contact, **args) || contact_job.scheduled_start_at,
            scheduled_end_at:   scheduled_end_at_from_webhook(contact, **args) || contact_job.scheduled_end_at,
            total_amount:       (args.dig(:totalDue).presence || contact_job.total_amount).to_d,
            ext_tech_id:        args.dig(:servicedBy).to_s
          )

          contact_job
        end
        # example FieldRoutes "Appointment Status" webhook payload
        # {
        #   client_id:          '1',
        #   event:              'appointment_status_change',
        #   customerID:         '18748',
        #   fname:              'Govardhan',
        #   lname:              'Muthineni',
        #   companyName:        '',
        #   address:            '26855 North 72nd Lane',
        #   city:               'Peoria',
        #   state:              'AZ',
        #   zip:                '85383',
        #   email:              'Vardhan128US@gmail.com',
        #   billingCompanyName: '',
        #   billingFName:       'Govardhan',
        #   billingLName:       'Muthineni',
        #   billingAddress:     '26855 North 72nd Lane',
        #   billingCity:        'Peoria',
        #   billingState:       'AZ',
        #   billingZip:         '85383',
        #   totalDue:           '0.00',
        #   age:                '{{age}}',
        #   serviceType:        '541',
        #   serviceDate:        '2024-07-15',
        #   description:        'Pest',
        #   serviceDescription: 'Pest',
        #   phone1:             '9092674961',
        #   phone2:             '',
        #   officeID:           '2',
        #   servicedBy:         '1367',
        #   serviceStartTime:   '8:00 AM',
        #   serviceEndTime:     '8:00 PM',
        #   building:           '',
        #   unitNumber:         '',
        #   salesRep:           'Field Routes',
        #   salesRep2:          '',
        #   salesRep3:          '',
        #   techName:           'Gerald  Chavez',
        #   appointmentID:      '148203',
        #   techPhone:          '7604888459',
        #   techEmail:          'gecchavez79@yahoo.com',
        #   officeName:         'Bucksworth - Phoenix Office',
        #   subscriptionID:     '17071'
        # }

        def scheduled_end_at_from_webhook(contact, **args)
          Time.use_zone(contact.client.time_zone) { Chronic.parse("#{args.dig(:serviceDate).presence} #{args.dig(:serviceEndTime).presence}") }&.utc
        end

        def scheduled_start_at_from_webhook(contact, **args)
          Time.use_zone(contact.client.time_zone) { Chronic.parse("#{args.dig(:serviceDate).presence} #{args.dig(:serviceStartTime).presence}") }&.utc
        end
      end
    end
  end
end
