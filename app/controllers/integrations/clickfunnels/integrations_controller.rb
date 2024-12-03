# frozen_string_literal: true

# app/controllers/integrations/clickfunnels/integrations_controller.rb
module Integrations
  module Clickfunnels
    # endpoints supporting ClickFunnels integrations
    class IntegrationsController < ApplicationController
      class IntegrationsControllerError < StandardError; end

      skip_before_action :verify_authenticity_token, only: %i[test endpoint_purchase_created endpoint_stripe_customer_created]

      # (POST) receive a Clickfunnels
      # /integrations/clickfunnels/purchase_created
      # integrations_clickfunnels_endpoint_purchase_created_path
      # integrations_clickfunnels_endpoint_purchase_created_url
      def endpoint_purchase_created
        data  = params.dig(:data)
        event = params.dig(:event).to_s

        if event == 'created' && data && data.include?('attributes') && data['attributes'].include?('contact') && data['attributes'].include?('products')
          # contact data was received
          contact     = data['attributes']['contact']
          products    = data['attributes']['products']

          firstname   = contact.include?('first-name') ? contact['first-name'].to_s : ''
          lastname    = contact.include?('last-name') ? contact['last-name'].to_s : ''
          phone       = contact.include?('phone') ? contact['phone'].to_s.clean_phone : ''
          email       = contact.include?('email') ? contact['email'].to_s : ''
          address1    = contact.include?('address') ? contact['address'].to_s : ''
          city        = contact.include?('city') ? contact['city'].to_s : ''
          state       = contact.include?('state') ? contact['state'].to_s : ''
          zip         = contact.include?('zip') ? contact['zip'].to_s : ''
          time_zone   = contact.include?('time-zone') ? contact['time-zone'].to_s : ''
          cust_token  = contact.include?('additional-info') && contact['additional-info'].include?('purchase') && contact['additional-info']['purchase'].include?('stripe-customer-token') ? contact['additional-info']['purchase']['stripe-customer-token'].to_s : ''
          stripe_plan = products[0].include?('stripe-plan') ? products[0]['stripe-plan'].to_s.split('___') : []

          if phone.present? && cust_token.present? && stripe_plan.present?
            # phone & credit card token was parsed from data

            # find Package
            package = Package.find_by(tenant: I18n.t('tenant.id'), package_key: stripe_plan[0])

            # find PackagePage
            package_page = PackagePage.find_by(tenant: I18n.t('tenant.id'), page_key: stripe_plan[1])

            if package && package_page
              new_client_hash = {
                name:       Friendly.new.fullname(firstname, lastname),
                address1:,
                city:,
                state:,
                zip:,
                phone:,
                time_zone:,
                tenant:     I18n.t('tenant.id'),
                card_token: cust_token
              }

              new_user_hash = {
                firstname:,
                lastname:,
                email:,
                phone:
              }

              NewClient.delay(
                priority: DelayedJob.job_priority('new_client_create'),
                queue:    DelayedJob.job_queue('new_client_create'),
                user_id:  0,
                process:  'new_client_create'
              ).create(
                client:             new_client_hash,
                user:               new_user_hash,
                package_id:         package.id,
                package_page_id:    package_page.id,
                create_cc_customer: false,
                credit_card:        true,
                charge_client:      false,
                send_invite:        true
              )
            end
          else
            error = IntegrationsControllerError.new('Incomplete data.')
            error.set_backtrace(BC.new.clean(caller))

            Appsignal.report_error(error) do |transaction|
              # Only needed if it needs to be different or there's no active transaction from which to inherit it
              Appsignal.set_action('Integrations::Clickfunnels::IntegrationsController#endpoint_purchase_created')

              # Only needed if you want to set different arguments or there's no active transaction from which to inherit it
              Appsignal.add_params(params)

              Appsignal.set_tags(
                error_level: 'error',
                error_code:  0
              )
              Appsignal.add_custom_data(
                phone:,
                cust_token:,
                stripe_plan:,
                file:        __FILE__,
                line:        __LINE__
              )
            end
          end
        else
          error = IntegrationsControllerError.new('Incomplete data.')
          error.set_backtrace(BC.new.clean(caller))

          Appsignal.report_error(error) do |transaction|
            # Only needed if it needs to be different or there's no active transaction from which to inherit it
            Appsignal.set_action('Integrations::Clickfunnels::IntegrationsController#endpoint_purchase_created')

            # Only needed if you want to set different arguments or there's no active transaction from which to inherit it
            Appsignal.add_params(params)

            Appsignal.set_tags(
              error_level: 'error',
              error_code:  0
            )
            Appsignal.add_custom_data(
              event:,
              data_attributes: (data.include?('attributes') ? data['attributes'] : 'Not found'),
              file:            __FILE__,
              line:            __LINE__
            )
          end
        end

        respond_to do |format|
          format.json { render json: { message: 'Success!', status: 200 } }
          format.js   { render js: '', layout: false, status: :ok }
          format.html { render plain: 'Success!', content_type: 'text/plain', layout: false, status: :ok }
        end
      end
      # {
      # 	"data": {
      # 		"id": "52241939",
      # 		"type": "purchases",
      # 		"attributes": {
      # 			"products": [
      # 				{
      # 					"id": 2504154,
      # 					"name": "GPS University $99 Monthly Membership",
      # 					"stripe-plan": "0003",
      # 					"amount": {
      # 						"fractional": "0.0",
      # 						"currency": {
      # 							"id": "usd",
      # 							"alternate_symbols": [
      # 								"US$"
      # 							],
      # 							"decimal_mark": ".",
      # 							"disambiguate_symbol": "US$",
      # 							"html_entity": "$",
      # 							"iso_code": "USD",
      # 							"iso_numeric": "840",
      # 							"name": "United States Dollar",
      # 							"priority": 1,
      # 							"smallest_denomination": 1,
      # 							"subunit": "Cent",
      # 							"subunit_to_unit": 100,
      # 							"symbol": "$",
      # 							"symbol_first": true,
      # 							"thousands_separator": ","
      # 						},
      # 						"bank": {
      # 							"store": {
      # 								"index": {
      # 									"EUR_TO_USD": "1.0977",
      # 									"EUR_TO_JPY": "119.36",
      # 									"EUR_TO_BGN": "1.9558",
      # 									"EUR_TO_CZK": "27.299",
      # 									"EUR_TO_DKK": "7.4606",
      # 									"EUR_TO_GBP": "0.89743",
      # 									"EUR_TO_HUF": "355.65",
      # 									"EUR_TO_PLN": "4.5306",
      # 									"EUR_TO_RON": "4.8375",
      # 									"EUR_TO_SEK": "11.0158",
      # 									"EUR_TO_CHF": "1.0581",
      # 									"EUR_TO_ISK": "154.0",
      # 									"EUR_TO_NOK": "11.6558",
      # 									"EUR_TO_HRK": "7.614",
      # 									"EUR_TO_RUB": "86.3819",
      # 									"EUR_TO_TRY": "7.0935",
      # 									"EUR_TO_AUD": "1.8209",
      # 									"EUR_TO_BRL": "5.5905",
      # 									"EUR_TO_CAD": "1.5521",
      # 									"EUR_TO_CNY": "7.7894",
      # 									"EUR_TO_HKD": "8.5095",
      # 									"EUR_TO_IDR": "17716.88",
      # 									"EUR_TO_ILS": "3.9413",
      # 									"EUR_TO_INR": "82.8695",
      # 									"EUR_TO_KRW": "1346.31",
      # 									"EUR_TO_MXN": "25.8329",
      # 									"EUR_TO_MYR": "4.7619",
      # 									"EUR_TO_NZD": "1.8548",
      # 									"EUR_TO_PHP": "56.125",
      # 									"EUR_TO_SGD": "1.5762",
      # 									"EUR_TO_THB": "35.769",
      # 									"EUR_TO_ZAR": "19.3415",
      # 									"EUR_TO_EUR": 1
      # 								},
      # 								"options": {
      # 								},
      # 								"mutex": {
      # 								},
      # 								"in_transaction": false
      # 							},
      # 							"rounding_method": null,
      # 							"currency_string": null,
      # 							"rates_updated_at": "2020-03-27T00:00:00.000+00:00",
      # 							"last_updated": "2020-03-27T16:31:42.763+00:00"
      # 						}
      # 					},
      # 					"amount-currency": "USD",
      # 					"created-at": "2019-12-31T22:27:14.000Z",
      # 					"updated-at": "2020-03-27T18:35:59.000Z",
      # 					"subject": "FieldControlPro - Thank you",
      # 					"html-body": "\r\n\r\n<p style=\"letter-spacing: -0.3px;\">Thank you for your purchase</p>\r\n<p style=\"letter-spacing: -0.3px;\">You may access your Thank You Page here anytime:</p>\r\n<p style=\"letter-spacing: -0.3px;\">#PRODUCT_THANK_YOU_PAGE#</p>\r\n<p style=\"letter-spacing: -0.3px;\"><br></p>\r\n<p style=\"letter-spacing: -0.3px;\">Cheers!</p>\r\n<p style=\"letter-spacing: -0.3px;\"><span style=\"letter-spacing: -0.3px;background-color: transparent;\">GrossProfitSuccess Team</span></p>\r\n\r\n\r\n\r\n\r\n",
      # 					"thank-you-page-id": 46959206,
      # 					"stripe-cancel-after-payments": null,
      # 					"braintree-cancel-after-payments": null,
      # 					"bump": false,
      # 					"cart-product-id": null,
      # 					"billing-integration": "stripe_account-131753",
      # 					"infusionsoft-product-id": null,
      # 					"braintree-plan": null,
      # 					"infusionsoft-subscription-id": null,
      # 					"ontraport-product-id": null,
      # 					"ontraport-payment-count": null,
      # 					"ontraport-payment-type": null,
      # 					"ontraport-unit": null,
      # 					"ontraport-gateway-id": null,
      # 					"ontraport-invoice-id": null,
      # 					"commissionable": false,
      # 					"statement-descriptor": "$99 GPS University Mem",
      # 					"netsuite-id": null,
      # 					"netsuite-tag": null,
      # 					"netsuite-class": null
      # 				}
      # 			],
      # 			"member-id": null,
      # 			"contact": {
      # 				"id": 1134512709,
      # 				"page-id": 35163203,
      # 				"first-name": "Taylor",
      # 				"last-name": "Roberts",
      # 				"name": "Taylor Roberts ",
      # 				"address": "1234 Test St",
      # 				"city": "Test",
      # 				"country": "US",
      # 				"state": "UT",
      # 				"zip": "84062",
      # 				"email": "taylor@chiirp.com",
      # 				"phone": "9517414153",
      # 				"webinar-at": null,
      # 				"webinar-last-time": null,
      # 				"webinar-ext": "StHmEnfe",
      # 				"created-at": "2020-03-27T18:36:19.000Z",
      # 				"updated-at": "2020-03-27T18:36:19.000Z",
      # 				"ip": "172.68.211.180",
      # 				"funnel-id": 8362125,
      # 				"funnel-step-id": 46948290,
      # 				"unsubscribed-at": null,
      # 				"cf-uvid": "null",
      # 				"cart-affiliate-id": "",
      # 				"shipping-address": "1234 Test St",
      # 				"shipping-city": "Test",
      # 				"shipping-country": "US",
      # 				"shipping-state": "UT",
      # 				"shipping-zip": "84062",
      # 				"vat-number": "",
      # 				"affiliate-id": null,
      # 				"aff-sub": "paused_modal",
      # 				"aff-sub2": "clickfunnelsvsleadpagespricingchart1",
      # 				"cf-affiliate-id": null,
      # 				"contact-profile": {
      # 					"id": 525868193,
      # 					"first-name": "Taylor",
      # 					"last-name": "Roberts",
      # 					"address": "1234 Test St",
      # 					"city": "Test",
      # 					"country": "US",
      # 					"state": "UT",
      # 					"zip": "84062",
      # 					"email": "taylor@chiirp.com",
      # 					"phone": "9517414153",
      # 					"created-at": "2020-01-09T17:53:41.000Z",
      # 					"updated-at": "2020-03-27T17:26:44.000Z",
      # 					"unsubscribed-at": null,
      # 					"cf-uvid": "b6c088a1a7d48187cd013dfd8d6ec573",
      # 					"shipping-address": "1234 Test St",
      # 					"shipping-country": "US",
      # 					"shipping-city": "Test",
      # 					"shipping-state": "UT",
      # 					"shipping-zip": "84062",
      # 					"vat-number": null,
      # 					"middle-name": null,
      # 					"websites": null,
      # 					"location-general": null,
      # 					"normalized-location": null,
      # 					"deduced-location": null,
      # 					"age": null,
      # 					"gender": null,
      # 					"age-range-lower": null,
      # 					"age-range-upper": null,
      # 					"action-score": 50,
      # 					"known-ltv": "396.00",
      # 					"tags": [
      # 						"employee",
      # 						"gps-membership"
      # 					]
      # 				},
      # 				"additional-info": {
      # 					"cf-affiliate-id": "81701",
      # 					"time-zone": "Mountain Time (US & Canada)",
      # 					"utm-source": "",
      # 					"utm-medium": "",
      # 					"utm-campaign": "",
      # 					"utm-term": "",
      # 					"utm-content": "",
      # 					"cf-uvid": "null",
      # 					"webinar-delay": "-63752528169762",
      # 					"purchase": {
      # 						"product-ids": [
      # 							"2504154"
      # 						],
      # 						"payment-method-nonce": "",
      # 						"order-saas-url": "",
      # 						"stripe-customer-token": "tok_1GRN2VJ96TKvIIHT0ShVJ3cr"
      # 					}
      # 				},
      # 				"time-zone": "Mountain Time (US & Canada)"
      # 			},
      # 			"funnel-id": 8362125,
      # 			"stripe-customer-token": "tok_1GRN2VJ96TKvIIHT0ShVJ3cr",
      # 			"created-at": "2020-03-27T18:36:20.000Z",
      # 			"updated-at": "2020-03-27T18:36:20.000Z",
      # 			"subscription-id": "sub_GzLk7kmwrYvSUk",
      # 			"charge-id": null,
      # 			"ctransreceipt": null,
      # 			"status": "paid",
      # 			"fulfillment-status": null,
      # 			"fulfillment-id": null,
      # 			"fulfillments": {
      # 			},
      # 			"payments-count": null,
      # 			"infusionsoft-ccid": null,
      # 			"oap-customer-id": null,
      # 			"braintree-customer-id": null,
      # 			"payment-instrument-type": null,
      # 			"original-amount-cents": 9900,
      # 			"original-amount": {
      # 				"fractional": "9900.0",
      # 				"currency": {
      # 					"id": "usd",
      # 					"alternate_symbols": [
      # 						"US$"
      # 					],
      # 					"decimal_mark": ".",
      # 					"disambiguate_symbol": "US$",
      # 					"html_entity": "$",
      # 					"iso_code": "USD",
      # 					"iso_numeric": "840",
      # 					"name": "United States Dollar",
      # 					"priority": 1,
      # 					"smallest_denomination": 1,
      # 					"subunit": "Cent",
      # 					"subunit_to_unit": 100,
      # 					"symbol": "$",
      # 					"symbol_first": true,
      # 					"thousands_separator": ","
      # 				},
      # 				"bank": {
      # 					"store": {
      # 						"index": {
      # 							"EUR_TO_USD": "1.0977",
      # 							"EUR_TO_JPY": "119.36",
      # 							"EUR_TO_BGN": "1.9558",
      # 							"EUR_TO_CZK": "27.299",
      # 							"EUR_TO_DKK": "7.4606",
      # 							"EUR_TO_GBP": "0.89743",
      # 							"EUR_TO_HUF": "355.65",
      # 							"EUR_TO_PLN": "4.5306",
      # 							"EUR_TO_RON": "4.8375",
      # 							"EUR_TO_SEK": "11.0158",
      # 							"EUR_TO_CHF": "1.0581",
      # 							"EUR_TO_ISK": "154.0",
      # 							"EUR_TO_NOK": "11.6558",
      # 							"EUR_TO_HRK": "7.614",
      # 							"EUR_TO_RUB": "86.3819",
      # 							"EUR_TO_TRY": "7.0935",
      # 							"EUR_TO_AUD": "1.8209",
      # 							"EUR_TO_BRL": "5.5905",
      # 							"EUR_TO_CAD": "1.5521",
      # 							"EUR_TO_CNY": "7.7894",
      # 							"EUR_TO_HKD": "8.5095",
      # 							"EUR_TO_IDR": "17716.88",
      # 							"EUR_TO_ILS": "3.9413",
      # 							"EUR_TO_INR": "82.8695",
      # 							"EUR_TO_KRW": "1346.31",
      # 							"EUR_TO_MXN": "25.8329",
      # 							"EUR_TO_MYR": "4.7619",
      # 							"EUR_TO_NZD": "1.8548",
      # 							"EUR_TO_PHP": "56.125",
      # 							"EUR_TO_SGD": "1.5762",
      # 							"EUR_TO_THB": "35.769",
      # 							"EUR_TO_ZAR": "19.3415",
      # 							"EUR_TO_EUR": 1
      # 						},
      # 						"options": {
      # 						},
      # 						"mutex": {
      # 						},
      # 						"in_transaction": false
      # 					},
      # 					"rounding_method": null,
      # 					"currency_string": null,
      # 					"rates_updated_at": "2020-03-27T00:00:00.000+00:00",
      # 					"last_updated": "2020-03-27T16:31:42.763+00:00"
      # 				}
      # 			},
      # 			"original-amount-currency": "USD",
      # 			"manual": false,
      # 			"error-message": null,
      # 			"nmi-customer-vault-id": null
      # 		}
      # 	},
      # 	"jsonapi": {
      # 		"version": "1.0"
      # 	},
      # 	"event": "created"
      # }

      # (POST) receive Stripe customer data after ClickFunnels purchase
      # /integrations/clickfunnels/stripe_customer_created
      # integrations_clickfunnels_endpoint_stripe_customer_created_path
      # integrations_clickfunnels_endpoint_stripe_customer_created_url
      def endpoint_stripe_customer_created
        data      = params.dig(:data)
        client_id = data.dig('object', 'id').to_s
        card_id   = data.dig('object', 'default_source').to_s

        if client_id.present? && card_id.present?
          NewClient.delay(
            priority: DelayedJob.job_priority('new_client_create'),
            queue:    DelayedJob.job_queue('new_client_create'),
            run_at:   5.minutes.from_now,
            user_id:  0,
            process:  'new_client_endpoint_stripe_customer_created'
          ).update_client_token_from_card_token(
            client_id:,
            card_id:
          )
        end

        respond_to do |format|
          format.json { render json: { message: 'Success!', status: 200 } }
          format.js   { render js: '', layout: false, status: :ok }
          format.html { render plain: 'Success!', content_type: 'text/plain', layout: false, status: :ok }
        end
      end
      # {
      # 	"id": "evt_1GSnJOJ96TKvIIHTjiY0V50B",
      # 	"object": "event",
      # 	"api_version": "2019-03-14",
      # 	"created": 1585673498,
      # 	"data": {
      # 		"object": {
      # 			"id": "cus_H0ox21cau9luSW",
      # 			"object": "customer",
      # 			"account_balance": 0,
      # 			"address": null,
      # 			"balance": 0,
      # 			"created": 1585673498,
      # 			"currency": null,
      # 			"default_source": "card_1GSnJNJ96TKvIIHTLWhJAQ77",
      # 			"delinquent": false,
      # 			"description": "taylor@chiirp.com",
      # 			"discount": null,
      # 			"email": "taylor@chiirp.com",
      # 			"invoice_prefix": "9252FE52",
      # 			"invoice_settings": {
      # 				"custom_fields": null,
      # 				"default_payment_method": null,
      # 				"footer": null
      # 			},
      # 			"livemode": false,
      # 			"metadata": {
      # 				"name": "Taylor Roberts ",
      # 				"first_name": "Taylor",
      # 				"last_name": "Roberts",
      # 				"phone": "9517414153",
      # 				"address": "1234 Test St, Test, UT, 84062, US",
      # 				"shipping_address": "1234 Test St, Test, UT, 84062, US"
      # 			},
      # 			"name": null,
      # 			"next_invoice_sequence": 1,
      # 			"phone": null,
      # 			"preferred_locales": [
      # 			],
      # 			"shipping": {
      # 				"address": {
      # 					"city": "Test",
      # 					"country": "US",
      # 					"line1": "1234 Test St",
      # 					"line2": null,
      # 					"postal_code": "84062",
      # 					"state": "UT"
      # 				},
      # 				"name": "",
      # 				"phone": ""
      # 			},
      # 			"sources": {
      # 				"object": "list",
      # 				"data": [
      # 					{
      # 						"id": "card_1GSZDcJ96TKvIIHTTHHQXrGn",
      # 						"object": "card",
      # 						"address_city": null,
      # 						"address_country": null,
      # 						"address_line1": null,
      # 						"address_line1_check": null,
      # 						"address_line2": null,
      # 						"address_state": null,
      # 						"address_zip": null,
      # 						"address_zip_check": null,
      # 						"brand": "Visa",
      # 						"country": "CA",
      # 						"customer": "cus_H0ox21cau9luSW",
      # 						"cvc_check": "pass",
      # 						"dynamic_last4": null,
      # 						"exp_month": 4,
      # 						"exp_year": 2022,
      # 						"fingerprint": "huI3V3Q8jjkoaRTj",
      # 						"funding": "credit",
      # 						"last4": "1881",
      # 						"metadata": {
      # 						},
      # 						"name": null,
      # 						"tokenization_method": null
      # 					}
      # 				],
      # 				"has_more": false,
      # 				"total_count": 1,
      # 				"url": "/v1/customers/cus_H0ox21cau9luSW/sources"
      # 			},
      # 			"subscriptions": {
      # 				"object": "list",
      # 				"data": [
      # 				],
      # 				"has_more": false,
      # 				"total_count": 0,
      # 				"url": "/v1/customers/cus_H0ox21cau9luSW/subscriptions"
      # 			},
      # 			"tax_exempt": "none",
      # 			"tax_ids": {
      # 				"object": "list",
      # 				"data": [
      # 				],
      # 				"has_more": false,
      # 				"total_count": 0,
      # 				"url": "/v1/customers/cus_H0ox21cau9luSW/tax_ids"
      # 			},
      # 			"tax_info": null,
      # 			"tax_info_verification": null
      # 		}
      # 	},
      # 	"livemode": false,
      # 	"pending_webhooks": 3,
      # 	"request": {
      # 		"id": "req_JhFZSBa7adm4oz",
      # 		"idempotency_key": "5e582a79-704c-400b-b265-8dfcd12aea3a"
      # 	},
      # 	"type": "customer.created"
      # }

      # (POST) Clickfunnels webhook test
      # /funnel_webhooks/test
      # /integrations/clickfunnels/test
      # integrations_clickfunnels_test_path
      # integrations_clickfunnels_test_url
      def test
        Rails.logger.info '<--- BEGIN CLICKFUNNELS WEBHOOK TEST --->'
        Rails.logger.info "Clickfunnels Webhook Test Params: #{params.inspect} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"
        Rails.logger.info "Clickfunnels time (UTC): #{params[:time].inspect} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"
        Rails.logger.info "request.url: #{request.url.inspect} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"
        Rails.logger.info "request.headers['X-Clickfunnels-Webhook-Delivery-Id']: #{request.headers['X-Clickfunnels-Webhook-Delivery-Id'].inspect} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"
        Rails.logger.info "request.body: #{request.body.read.inspect} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"

        md_5 = Digest::MD5.new
        md_5.update request.url
        md_5.update request.body.read

        if md_5 == request.headers['X-Clickfunnels-Webhook-Delivery-Id']
          Rails.logger.info "Clickfunnels MD5 Successful!: File: #{__FILE__} - Line: #{__LINE__}"
        else
          Rails.logger.info "Clickfunnels MD5 Unsuccessful!: File: #{__FILE__} - Line: #{__LINE__}"
          Rails.logger.info "Calculated MD5: #{md_5.inspect} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"
        end

        Rails.logger.info '<--- END CLICKFUNNELS WEBHOOK TEST --->'

        respond_to do |format|
          format.json { render json: { message: 'Success!', status: 200 } }
          format.js   { render js: '', layout: false, status: :ok }
          format.html { render plain: 'Success!', content_type: 'text/plain', layout: false, status: :ok }
        end
      end
    end
  end
end
