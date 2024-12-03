# frozen_string_literal: true

# app/controllers/integrations/jobnimbus/webhook_samples_controller.rb
# rubocop:disable all
module Integrations
  module Jobnimbus
    # sample data received from JobNimbus
    class WebhookSamplesController < Jobnimbus::IntegrationsController
      def webhook_contact
        {
          "zip": "",
          "city": "",
          "jnid": "l2j4ea8529tvb1alzot4k58",
          "tags": [
          ],
          "type": "contact",
          "email": "",
          "number": "1003",
          "owners": [
            {
              "id": "l2j4danenq3zvc1h2z6w614",
              "name": "Kevin Neubert",
              "email": "kevin@chiirp.com"
            }
          ],
          "company": "",
          "related": [
          ],
          "website": "",
          "date_end": 0,
          "location": {
            "id": 1
          },
          "last_name": "Neubert",
          "sales_rep": "l2j4danenq3zvc1h2z6w614",
          "created_by": "l2j4danenq3zvc1h2z6w614",
          "date_start": 0,
          "fax_number": "",
          "first_name": "Kevin",
          "home_phone": "",
          "state_text": "",
          "work_phone": "",
          "description": null,
          "external_id": null,
          "source_name": null,
          "status_name": "Lead",
          "country_name": "United States",
          "date_created": 1651157253,
          "date_updated": 1651169720,
          "display_name": "Kevin Neubert",
          "mobile_phone": "8023455136",
          "address_line1": "",
          "address_line2": "",
          "sales_rep_name": "Kevin Neubert",
          "created_by_name": "Kevin Neubert",
          "sales_rep_email": "kevin@chiirp.com",
          "created_by_email": "kevin@chiirp.com",
          "record_type_name": "Retail",
          "date_status_change": 1651157253
        }
      end

      def webhook_estimate
        {
          "jnid": "l2j9yfqeakkilzvt3b4bueu",
          "note": null,
          "type": "estimate",
          "number": "1001",
          "owners": [
            {
              "id": "l2j4danenq3zvc1h2z6w614",
              "name": "Kevin Neubert",
              "email": "kevin@chiirp.com"
            }
          ],
          "related": [
            {
              "id": "l2j4ea8529tvb1alzot4k58",
              "name": "Kevin Neubert",
              "type": "contact",
              "number": "1003"
            }
          ],
          "location": {
            "id": 1
          },
          "sales_rep": "l2j4danenq3zvc1h2z6w614",
          "created_by": "l2j4danenq3zvc1h2z6w614",
          "external_id": null,
          "status_name": "Draft",
          "date_created": 1651166591,
          "date_updated": 1651169993,
          "internal_note": null,
          "sales_rep_name": "Kevin Neubert",
          "created_by_name": "Kevin Neubert",
          "sales_rep_email": "kevin@chiirp.com",
          "created_by_email": "kevin@chiirp.com",
          "date_status_change": 1651166591
        }
      end

      def webhook_invoice
        {
          "jnid": "l2khuj5leqddq8x1ps1hy1x",
          "note": "",
          "type": "invoice",
          "number": "1001",
          "owners": [
            {
              "id": "l2j4danenq3zvc1h2z6w614",
              "name": "Kevin Neubert",
              "email": "kevin@chiirp.com"
            }
          ],
          "related": [
            {
              "id": "l2j4ea8529tvb1alzot4k58",
              "name": "Kevin Neubert",
              "type": "contact",
              "number": "1003"
            }
          ],
          "location": {
            "id": 1
          },
          "sales_rep": "l2j4danenq3zvc1h2z6w614",
          "created_by": "l2j4danenq3zvc1h2z6w614",
          "external_id": null,
          "status_name": "Draft",
          "date_created": 1651240312,
          "date_updated": 1651240422,
          "internal_note": "",
          "sales_rep_name": "Kevin Neubert",
          "created_by_name": "Kevin Neubert",
          "sales_rep_email": "kevin@chiirp.com",
          "created_by_email": "kevin@chiirp.com",
          "date_status_change": 1651240312
        }
      end

      def webhook_workorder
        {
          "jnid": "l2kexs364squk0dcevr379j",
          "type": "workorder",
          "number": "1001",
          "owners": [
            {
              "id": "l2j4danenq3zvc1h2z6w614",
              "name": "Kevin Neubert",
              "email": "kevin@chiirp.com"
            }
          ],
          "related": [
            {
              "id": "l2j4ea8529tvb1alzot4k58",
              "name": "Kevin Neubert",
              "type": "contact",
              "number": "1003"
            }
          ],
          "date_end": 0,
          "location": {
            "id": 1
          },
          "sales_rep": "l2j4danenq3zvc1h2z6w614",
          "created_by": "l2j4danenq3zvc1h2z6w614",
          "date_start": 1651204800,
          "external_id": null,
          "status_name": "Assigned",
          "date_created": 1651235424,
          "date_updated": 1651238235,
          "customer_note": "",
          "internal_note": "",
          "created_by_name": "Kevin Neubert",
          "sales_rep_email": "kevin@chiirp.com",
          "created_by_email": "kevin@chiirp.com",
          "record_type_name": "Roof",
          "parent_fax_number": "",
          "parent_home_phone": "",
          "parent_work_phone": "",
          "date_status_change": 1651235424,
          "parent_mobile_phone": "8023455136"
        }
      end
    end
  end
end
