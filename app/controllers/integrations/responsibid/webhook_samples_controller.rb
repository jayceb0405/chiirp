# frozen_string_literal: true

# app/controllers/integrations/responsibid/webhook_samples_controller.rb
# rubocop:disable all
module Integrations
  module Responsibid
    # sample data received from ResponsiBid
    class WebhookSamplesController < Responsibid::IntegrationsController
      def zapier_html_post
        {
          "CompanyBid": {
            "is_migrated": nil,                            # Company Bid Is Migrated
            "commercial": "0",                             # Company Bid Commercial
            "status": "Scheduled",                         # Company Bid Status (open, pending, scheduled, closed, visit, declined, job in jobber)
            "date_pending": nil,                           # Company Bid Date Pending
            "date_scheduled": nil,                         # Company Bid Date Scheduled
            "date_closed": nil,                            # Company Bid Date Closed
            "date_declined": nil,                          # Company Bid Date Declined
            "closing_price": "2539",                       # Company Bid Closing Price
            "booking_date": "2022-04-06",                  # Company Bid Booking Date
            "booking_arrival_start_time": "09:15:00",      # Company Bid Booking Arrival Start Time
            "booking_arrival_end_time": "11:15:00",        # Company Bid Booking Arrival End Time
            "job_duration_hours": "8",                     # Company Bid Job Duration Hours
            "job_duration_minutes": "30",                  # Company Bid Job Duration Minutes
            "notes": "Test\ntest note 4",                  # Company Bid Notes (private)
            "availability_1_date": nil,                    # Company Bid Availability 1 Date
            "availability_1_time_of_day": nil,             # Company Bid Availability 1 Time Of Day
            "availability_2_date": nil,                    # Company Bid Availability 2 Date
            "availability_2_time_of_day": nil,             # Company Bid Availability 2 Time Of Day
            "availability_3_date": nil,                    # Company Bid Availability 3 Date
            "availability_3_time_of_day": nil,             # Company Bid Availability 3 Time Of Day
            "availability_4_date": nil,                    # Company Bid Availability 4 Date
            "availability_4_time_of_day": nil,             # Company Bid Availability 4 Time Of Day
            "availability_5_date": nil,                    # Company Bid Availability 5 Date
            "availability_5_time_of_day": nil,             # Company Bid Availability 5 Time Of Day
            "origin_ip": nil,                              # Company Bid Origin Ip
            "referring_url": "Call Screen",                # Company Bid Referring URL
            "http_user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/90.0.4430.93 Safari/537.36",     # Company Bid Http User Agent
            "originated_from_hatch": false,                # Company Bid Originated From Hatch
            "special_instruction": "",                     # Company Bid Special Instruction (public)
            "signature": "Weirdo Beardo",                  # Company Bid Signature
            "signature_date": "2022-02-22 01:23:58",       # Company Bid Signature Date
            "signature_ip": "130.51.202.32"                # Company Bid Signature Ip
          },
          "Contact": {
            "id": "1344530",                               # Contact ID
            "first_name": "Wierdo",                        # Contact First Name
            "last_name": "Beardo",                         # Contact Last Name
            "street1": "2050 E Baseline Rd",               # Contact Street1
            "street2": "",                                 # Contact Street2
            "zip": "85204",                                # Contact Zip
            "phone1": "4805661212",                        # Contact Phone1
            "phone2": "",                                  # Contact Phone2
            "email": "wierdo@symphosize.com",              # Contact Email
            "country": "USA",                              # Contact Country
            "company_name": "",                            # Contact Company Name
            "opt_out": "1",                                # Contact Opt Out
            "explicit_opt_in": false,                      # Contact Explicit Opt In
            "explicit_sms_opt_in": false,                  # Contact Explicit Sms Opt In
            "lead_source": "Bing",                         # Contact Lead Source
            "service_area": "Gilbert, AZ"                  # Contact Service Area
          },
          "SelectedServices": "Concrete Cleaning Patio Deluxe $169\nDeck Cleaning Premium $469\nFence Cleaning Premium $450\nHouse Washing Premium $650\nWindow Cleaning Premium $801\n", # Selected Services
          "SelectedServicesWithoutPricing": "Concrete Cleaning Patio Deluxe\nDeck Cleaning Premium\nFence Cleaning Premium\nHouse Washing Premium\nWindow Cleaning Premium\n",            # Selected Services Without Pricing
          "SelectedServicesTotalAmount": 2539,             # Selected Services Total Amount
          "Services": {
            "CustomItem1": {
              "requested": false,                          # Services Custom Item1 Requested
              "name": false,                               # Services Custom Item1 Name
              "package_requested": false,                  # Services Custom Item1 Package Requested
              "basic_price": false,                        # Services Custom Item1 Basic Price
              "deluxe_price": false,                       # Services Custom Item1 Deluxe Price
              "premium_price": false                       # Services Custom Item1 Premium Price
            },
            "CustomItem2": {
              "requested": false,                          # Services Custom Item2 Requested
              "name": false,                               # Services Custom Item2 Name
              "package_requested": false,                  # Services Custom Item2 Package Requested
              "basic_price": false,                        # Services Custom Item2 Basic Price
              "deluxe_price": false,                       # Services Custom Item2 Deluxe Price
              "premium_price": false                       # Services Custom Item2 Premium Price
            },
            "CustomItem3": {
              "requested": false,                          # Services Custom Item3 Requested
              "name": false,                               # Services Custom Item3 Name
              "package_requested": false,                  # Services Custom Item3 Package Requested
              "basic_price": false,                        # Services Custom Item3 Basic Price
              "deluxe_price": false,                       # Services Custom Item3 Deluxe Price
              "premium_price": false                       # Services Custom Item3 Premium Price
            },
            "CustomItem4": {
              "requested": false,                          # Services Custom Item4 Requested
              "name": false,                               # Services Custom Item4 Name
              "package_requested": false,                  # Services Custom Item4 Package Requested
              "basic_price": false,                        # Services Custom Item4 Basic Price
              "deluxe_price": false,                       # Services Custom Item4 Deluxe Price
              "premium_price": false                       # Services Custom Item4 Premium Price
            },
            "CustomItem5": {
              "requested": false,                          # Services Custom Item5 Requested
              "name": false,                               # Services Custom Item5 Name
              "package_requested": false,                  # Services Custom Item5 Package Requested
              "basic_price": false,                        # Services Custom Item5 Basic Price
              "deluxe_price": false,                       # Services Custom Item5 Deluxe Price
              "premium_price": false                       # Services Custom Item5 Premium Price
            },
            "CustomItem6": {
              "requested": false,                          # Services Custom Item6 Requested
              "name": false,                               # Services Custom Item6 Name
              "package_requested": false,                  # Services Custom Item6 Package Requested
              "basic_price": false,                        # Services Custom Item6 Basic Price
              "deluxe_price": false,                       # Services Custom Item6 Deluxe Price
              "premium_price": false                       # Services Custom Item6 Premium Price
            },
            "CustomItem7": {
              "requested": false,                          # Services Custom Item7 Requested
              "name": false,                               # Services Custom Item7 Name
              "package_requested": false,                  # Services Custom Item7 Package Requested
              "basic_price": false,                        # Services Custom Item7 Basic Price
              "deluxe_price": false,                       # Services Custom Item7 Deluxe Price
              "premium_price": false                       # Services Custom Item7 Premium Price
            },
            "CustomItem8": {
              "requested": false,                          # Services Custom Item8 Requested
              "name": false,                               # Services Custom Item8 Name
              "package_requested": false,                  # Services Custom Item8 Package Requested
              "basic_price": false,                        # Services Custom Item8 Basic Price
              "deluxe_price": false,                       # Services Custom Item8 Deluxe Price
              "premium_price": false                       # Services Custom Item8 Premium Price
            },
            "CustomItem9": {
              "requested": false,                          # Services Custom Item9 Requested
              "name": false,                               # Services Custom Item9 Name
              "package_requested": false,                  # Services Custom Item9 Package Requested
              "basic_price": false,                        # Services Custom Item9 Basic Price
              "deluxe_price": false,                       # Services Custom Item9 Deluxe Price
              "premium_price": false                       # Services Custom Item9 Premium Price
            },
            "CustomItem10": {
              "requested": false,                          # Services Custom Item10 Requested
              "name": false,                               # Services Custom Item10 Name
              "package_requested": false,                  # Services Custom Item10 Package Requested
              "basic_price": false,                        # Services Custom Item10 Basic Price
              "deluxe_price": false,                       # Services Custom Item10 Deluxe Price
              "premium_price": false                       # Services Custom Item10 Premium Price
            }
          },
          "event_id": "1234"
        }
      end
    end
  end
end
