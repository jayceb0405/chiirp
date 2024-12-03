# frozen_string_literal: true

# app/controllers/integrations/housecall/webhook_samples_controller.rb
# rubocop:disable all
module Integrations
  module Housecall
    class WebhookSamplesController < Housecall::IntegrationsController
      def estimate_created
        {
          "event"=>"estimate.created",
          "company_id"=>"5980a831-fc8f-47a6-9ac2-f1c6b924a03e",
          "estimate"=>{
            "id"=>"csr_b27b0d1c5683445ebcc93131e0572a7b",
            "estimate_number"=>"2926",
            "work_status"=>"scheduled",
            "lead_source"=>nil,
            "customer"=>{
              "id"=>"cus_fd1172ce57dd4056a14bf0069316607b",
              "first_name"=>"Jim",
              "last_name"=>"Kuell",
              "email"=>"JimKuell@gmail.com",
              "mobile_number"=>"3368177067",
              "home_number"=>nil,
              "work_number"=>nil,
              "company"=>nil,
              "notifications_enabled"=>true,
              "lead_source"=>nil,
              "notes"=>nil,
              "created_at"=>"2023-11-29T19:25:41Z",
              "updated_at"=>"2023-11-29T19:25:41Z",
              "company_name"=>"Triad Electrical Services",
              "company_id"=>"5980a831-fc8f-47a6-9ac2-f1c6b924a03e",
              "tags"=>[]
            },
            "address"=>{
              "id"=>"adr_0109a9c91ce947d5b983b593f3d67409",
              "type"=>"billing",
              "street"=>"102 Fernwood Cir",
              "street_line_2"=>nil,
              "city"=>"Cary",
              "state"=>"NC",
              "zip"=>"27511",
              "country"=>"US"
            },
            "created_at"=>"2023-11-29T19:27:18Z",
            "updated_at"=>"2023-11-29T19:27:19Z",
            "company_name"=>"Triad Electrical Services",
            "company_id"=>"5980a831-fc8f-47a6-9ac2-f1c6b924a03e",
            "work_timestamps"=>{
              "on_my_way_at"=>nil,
              "started_at"=>nil,
              "completed_at"=>nil
            },
            "schedule"=>{
              "scheduled_start"=>"2023-11-30T21:00:00Z",
              "scheduled_end"=>"2023-11-30T22:00:00Z",
              "arrival_window"=>120,
              "appointments"=>[]
            },
            "assigned_employees"=>[
              {
                "id"=>"pro_96f0fedb8dd3476192afd31401219443",
                "first_name"=>"Harvey",
                "last_name"=>"Aleman",
                "email"=>"harvinaleman@gmail.com",
                "mobile_number"=>"9199353665",
                "color_hex"=>"1777d3",
                "avatar_url"=>"/assets/add_image_thumb.png",
                "role"=>"field tech",
                "tags"=>[],
                "permissions"=>{
                  "can_add_and_edit_job"=>true,
                  "can_be_booked_online"=>false,
                  "can_call_and_text_with_customers"=>true,
                  "can_chat_with_customers"=>true,
                  "can_delete_and_cancel_job"=>true,
                  "can_edit_message_on_invoice"=>true,
                  "can_see_street_view_data"=>true,
                  "can_share_job"=>true,
                  "can_take_payment_see_prices"=>true,
                  "can_see_customers"=>true,
                  "can_see_full_schedule"=>true,
                  "can_see_future_jobs"=>true,
                  "can_see_marketing_campaigns"=>true,
                  "can_see_reporting"=>true,
                  "can_edit_settings"=>true,
                  "is_point_of_contact"=>false,
                  "is_admin"=>true
                },
                "company_name"=>"Triad Electrical Services",
                "company_id"=>"5980a831-fc8f-47a6-9ac2-f1c6b924a03e"
              }
            ],
            "estimate_fields"=>{"job_type"=>nil, "business_unit"=>nil},
            "options"=>[
              {
                "id"=>"est_69d963ba0829458ab3e4eb54873dcee7",
                "name"=>"Option #1",
                "option_number"=>"2926",
                "total_amount"=>0,
                "approval_status"=>nil,
                "status"=>"scheduled",
                "message_from_pro"=>nil,
                "tags"=>["TSC", "Area 3", "flexible"],
                "notes"=>[
                  {
                    "id"=>"nte_14076d06d93b4d618804b1b8e7ddc2a0",
                    "content"=>"Estimate \r\n11-30-2023 1. Hot tub disconnected\r\n2. Install outdoor outlet\r\n3. Running electrical to a shed\r\n     \r\n\r\n\r\n Lead  source: Google\r\nScheduled by: Kayla"
                  }
                ],
                "created_at"=>"2023-11-29T19:27:18Z",
                "updated_at"=>"2023-11-29T19:27:20Z",
                "attachments"=>[]
              }
            ]
          }
        }
      end

      def estimate_sent
        {
          "event"=>"estimate.sent",
          "company_id"=>"4cce1f08-9b75-4680-b20a-ced031d355b0",
          "estimate"=>{
            "id"=>"csr_a06cc0df5144482584507994f62238a9",
            "estimate_number"=>"34225",
            "work_status"=>"needs scheduling",
            "lead_source"=>nil,
            "customer"=>{
              "id"=>"cus_870026abe46b4610a304557eb696b142",
              "first_name"=>"Lacey",
              "last_name"=>"Dellinger",
              "email"=>"lhdellinger@gmail.com",
              "mobile_number"=>"8437093056",
              "home_number"=>nil,
              "work_number"=>nil,
              "company"=>nil,
              "notifications_enabled"=>true,
              "lead_source"=>nil,
              "notes"=>nil,
              "created_at"=>"2023-11-29T15:00:33Z",
              "updated_at"=>"2023-11-29T15:03:52Z",
              "company_name"=>"Squeegee Pros",
              "company_id"=>"4cce1f08-9b75-4680-b20a-ced031d355b0",
              "tags"=>["20 Referral"]
            },
            "address"=>{
              "id"=>"adr_7432610b3c33432d9f3a218e00b4e403",
              "type"=>"billing",
              "street"=>"3000 Grey Rd",
              "street_line_2"=>nil,
              "city"=>"Davidson",
              "state"=>"NC",
              "zip"=>"28036",
              "country"=>"US"
            },
            "created_at"=>"2023-11-29T15:01:01Z",
            "updated_at"=>"2023-11-29T15:01:01Z",
            "company_name"=>"Squeegee Pros",
            "company_id"=>"4cce1f08-9b75-4680-b20a-ced031d355b0",
            "work_timestamps"=>{
              "on_my_way_at"=>nil,
              "started_at"=>nil,
              "completed_at"=>nil
            },
            "schedule"=>{
              "scheduled_start"=>nil,
              "scheduled_end"=>nil,
              "arrival_window"=>0,
              "appointments"=>[]
            },
            "assigned_employees"=>[],
            "estimate_fields"=>{
              "job_type"=>nil,
              "business_unit"=>nil
            },
            "options"=>[
              {
                "id"=>"est_e7e2c2d1428b48318304eb1e2a59c768",
                "name"=>"Option #1",
                "option_number"=>"34225",
                "total_amount"=>57350,
                "approval_status"=>nil,
                "status"=>"submitted for signoff",
                "message_from_pro"=>"",
                "tags"=>["20 Referral", "70 Theresa"],
                "notes"=>[
                  {
                    "id"=>"nte_dcbf5b7fc21745949cde721dfa573558",
                    "content"=>"11/29/23 - Sched First Avail. - TMG"
                  }
                ],
                "created_at"=>"2023-11-29T15:01:01Z",
                "updated_at"=>"2023-11-29T15:06:37Z",
                "attachments"=>[]
              }
            ]
          }
        }
      end

      def job_appointment_appointment_discarded
        {
          "event"=>"job.appointment.appointment_discarded",
          "company_id"=>"a54a6c56-e59c-4ba8-8b0f-cc40a4432730",
          "appointment"=>{
            "id"=>"appt_ed49e91efb2a4ed589587a559c1e24f8",
            "job_id"=>"job_266f589c4b5d4a1894a67b592ce1a2e4"
          }
        }
      end

      def job_appointment_appointment_pros_assigned
        {
          "event"=>"job.appointment.appointment_pros_assigned",
          "company_id"=>"5f512e14-dc7c-43ef-8474-92668d4ed75f",
          "appointment"=>{
            "id"=>"appt_42103180fbc64526b4163dceeecabd9b",
            "start_time"=>"2023-10-30T21:00:00Z",
            "end_time"=>"2023-10-30T23:00:00Z",
            "arrival_window_minutes"=>120,
            "job_id"=>"job_16b6dd2011464f43ba752d320e9dcb3e",
            "dispatched_employees"=>[
              {
                "id"=>"pro_c4e07ab66f5349eaa745a8938a02fc01",
                "first_name"=>"Jose",
                "last_name"=>"Quintero",
                "email"=>"junior.quintero3@icloud.com",
                "mobile_number"=>"7255990231",
                "color_hex"=>"0089d1",
                "avatar_url"=>"https://housecall-attachments-production.s3.amazonaws.com/service_pros/avatars/000/925/190/thumb_round/avatar_1694125733.png?1694125733",
                "role"=>"field tech"
              }
            ]
          }
        }
      end

      def job_appointment_appointment_pros_unassigned
        {
          "event"=>"job.appointment.appointment_pros_unassigned",
          "company_id"=>"b2d66beb-2b29-42d5-a103-04cf7187cfba",
          "appointment"=>{
            "id"=>"appt_0f4d70de369d445db94513a5e4fd58f3",
            "start_time"=>"2025-06-30T17:45:00Z",
            "end_time"=>"2025-06-30T18:45:00Z",
            "arrival_window_minutes"=>60,
            "job_id"=>"job_a02b41f579a64cc286a5fc6832655d1e",
            "dispatched_employees"=>[
              {
                "id"=>"pro_1a65fe4fa6054c8282c7b0dc0eb6793c",
                "first_name"=>"Patricia",
                "last_name"=>"Plaza",
                "email"=>"patriciaplazaplaza77@gmail.com",
                "mobile_number"=>"3172844768",
                "color_hex"=>"e64a19",
                "avatar_url"=>nil,
                "role"=>"field tech"
              }, {
                "id"=>"pro_795df08e481c4bb19d15ef250fae3c19",
                "first_name"=>"Halison",
                "last_name"=>"Najera",
                "email"=>"najeraalison63@gmail.com",
                "mobile_number"=>"3179699246",
                "color_hex"=>"880d4f",
                "avatar_url"=>nil,
                "role"=>"field tech"
              }
            ]
          }
        }
      end

      def job_appointment_rescheduled
        {
          "event"=>"job.appointment.rescheduled",
          "company_id"=>"086bed3c-7ade-49e4-8d5c-879197d39e4d",
          "appointment"=>{
            "id"=>"appt_b21feacac71b44e4b6c50462e8531e66",
            "start_time"=>"2023-10-31T13:00:00Z",
            "end_time"=>"2023-10-31T14:00:00Z",
            "arrival_window_minutes"=>120,
            "job_id"=>"job_5456a0f859c74543ac598f99f0a3918b",
            "dispatched_employees"=>[
              {
                "id"=>"pro_91b0defb97644a59bb10eb56037c547a",
                "first_name"=>"Chris",
                "last_name"=>"Martin",
                "email"=>"chrismmartin@yahoo.com",
                "mobile_number"=>"2199737847",
                "color_hex"=>"03579b",
                "avatar_url"=>"https://housecall-attachments-production.s3.amazonaws.com/service_pros/avatars/000/603/713/thumb_round/avatar_1665530444.png?1665530444",
                "role"=>"field tech"
              }
            ]
          }
        }
      end

      def job_appointment_scheduled
        {
          "event"=>"job.appointment.scheduled",
          "company_id"=>"38004660-da3b-4bb8-9278-d447462bc43c",
          "appointment"=>{
            "id"=>"appt_f90b54884c4348a2b58d69950bcb63d0",
            "start_time"=>"2023-10-30T20:00:00Z",
            "end_time"=>"2023-10-30T21:00:00Z",
            "arrival_window_minutes"=>120,
            "job_id"=>"job_f1cec2ade07f49108275d697fdcbb1bc",
            "dispatched_employees"=>[
              {
                "id"=>"pro_08577ff8d6d8498982b9a140553a05df",
                "first_name"=>"Justin",
                "last_name"=>"Atwood",
                "email"=>"justin@upfrontservicesutah.com",
                "mobile_number"=>"8016692254",
                "color_hex"=>"8f25aa",
                "avatar_url"=>nil,
                "role"=>"field tech"
              }
            ]
          }
        }
      end

      def job_created
        {
          "event": "job.created",
          "company_id": "20a987bc-44ea-4315-be8f-f777adedb627",
          "job": {
            "id": "job_2520798734f14f559d8d5fce64ba27ce",
            "note": null,
            "tags": [
              "My Website"
            ],
            "address": {
              "id": "adr_9812fd8fe8f94f6da28c663fb1ce55c9",
              "zip": "11704",
              "city": "West Babylon",
              "type": "billing",
              "state": "NY",
              "street": "778 Carlton Road",
              "country": null,
              "street_line_2": null
            },
            "customer": {
              "id": "cus_d9883383185b4ef0a058f7288835d0ec",
              "tags": [
              ],
              "email": "jcasazza44@aol.com",
              "company": null,
              "last_name": "Fulton",
              "first_name": "Jaime",
              "home_number": null,
              "work_number": null,
              "mobile_number": "6317149358",
              "notifications_enabled": true
            },
            "schedule": {
              "scheduled_end": null,
              "arrival_window": 0,
              "scheduled_start": null
            },
            "description": "",
            "work_status": null,
            "total_amount": 0,
            "invoice_number": "3536",
            "work_timestamps": {
              "started_at": null,
              "completed_at": null,
              "on_my_way_at": null
            },
            "assigned_employees": [
              {
                "id": "pro_599f49bf03254f87b55016041f2bd121",
                "role": "field tech",
                "tags": [
                ],
                "email": "coolcleaninfo@gmail.com",
                "color_hex": "0089d1",
                "last_name": "B",
                "avatar_url": "https://housecall-attachments-production.s3.amazonaws.com/service_pros/avatars/000/562/964/thumb/avatar_1627002133.png?1627002133",
                "first_name": "Chris",
                "permissions": {
                  "is_admin": true,
                  "can_share_job": true,
                  "can_edit_settings": true,
                  "can_see_customers": true,
                  "can_see_reporting": true,
                  "can_see_future_jobs": true,
                  "is_point_of_contact": false,
                  "can_add_and_edit_job": true,
                  "can_be_booked_online": true,
                  "can_see_full_schedule": true,
                  "can_chat_with_customers": true,
                  "can_see_street_view_data": true,
                  "can_delete_and_cancel_job": true,
                  "can_edit_message_on_invoice": false,
                  "can_see_marketing_campaigns": true,
                  "can_take_payment_see_prices": true,
                  "can_call_and_text_with_customers": true
                },
                "mobile_number": "5165150124"
              }
            ],
            "outstanding_balance": 0,
            "original_estimate_id": null
          }
        }
      end

      def job_started
        {
          "event"=>"job.started",
          "company_id"=>"ae8afda8-3b9d-45d5-a5f2-307b2abb3816",
          "job"=>{
            "id"=>"job_54926b4572c74c328737f3d922b23b4c",
            "invoice_number"=>"58704",
            "description"=>"Visit #1",
            "customer"=>{
              "id"=>"cus_0b2bb437e2dc446884778b0ca14aa61e",
              "first_name"=>"Kasia",
              "last_name"=>"Stasiak",
              "email"=>"kgs2002@gmail.com",
              "mobile_number"=>"5089510488",
              "home_number"=>nil,
              "work_number"=>nil,
              "company"=>nil,
              "notifications_enabled"=>true,
              "lead_source"=>nil,
              "notes"=>nil,
              "created_at"=>"2023-07-18T20:42:42Z",
              "updated_at"=>"2023-08-02T22:52:34Z",
              "company_name"=>"Aristotle Air Conditioning & Heating",
              "company_id"=>"ae8afda8-3b9d-45d5-a5f2-307b2abb3816",
              "tags"=>[]
            },
            "address"=>{
              "id"=>"adr_870329d613b349a29d1261a19cf8d61b",
              "type"=>"billing",
              "street"=>"41430 N Prosperity Way",
              "street_line_2"=>nil,
              "city"=>"New River",
              "state"=>"AZ",
              "zip"=>"85086",
              "country"=>"US"
            },
            "notes"=>[],
            "work_status"=>"in progress",
            "work_timestamps"=>{
              "on_my_way_at"=>"2023-11-29T14:25:08Z",
              "started_at"=>"2023-11-29T15:06:48Z",
              "completed_at"=>nil
            },
            "schedule"=>{
              "scheduled_start"=>"2023-11-29T15:00:00Z",
              "scheduled_end"=>"2023-11-29T16:00:00Z",
              "arrival_window"=>240,
              "appointments"=>[]
            },
            "total_amount"=>0,
            "outstanding_balance"=>0,
            "assigned_employees"=>[
              {
                "id"=>"pro_e7bda6d1911b41ebafc5e5c5abb6b680",
                "first_name"=>"Adan",
                "last_name"=>"G.",
                "email"=>"tech06@aristotleair.com",
                "mobile_number"=>"6025243746",
                "color_hex"=>"09629d",
                "avatar_url"=>"https://housecall-attachments-production.s3.amazonaws.com/service_pros/avatars/000/449/927/thumb/avatar_1666367314.png?1666367314",
                "role"=>"field tech",
                "tags"=>["Technician"],
                "permissions"=>{
                  "can_add_and_edit_job"=>true,
                  "can_be_booked_online"=>false,
                  "can_call_and_text_with_customers"=>true,
                  "can_chat_with_customers"=>false,
                  "can_delete_and_cancel_job"=>false,
                  "can_edit_message_on_invoice"=>false,
                  "can_see_street_view_data"=>true,
                  "can_share_job"=>false,
                  "can_take_payment_see_prices"=>true,
                  "can_see_customers"=>false,
                  "can_see_full_schedule"=>true,
                  "can_see_future_jobs"=>true,
                  "can_see_marketing_campaigns"=>false,
                  "can_see_reporting"=>false,
                  "can_edit_settings"=>false,
                  "is_point_of_contact"=>false,
                  "is_admin"=>false
                },
                "company_name"=>"Aristotle Air Conditioning & Heating",
                "company_id"=>"ae8afda8-3b9d-45d5-a5f2-307b2abb3816"
              }
            ],
            "tags"=>[],
            "original_estimate_id"=>nil,
            "lead_source"=>nil,
            "job_fields"=>{
              "job_type"=>nil,
              "business_unit"=>nil
            },
            "created_at"=>"2023-11-27T16:44:35Z",
            "updated_at"=>"2023-11-29T14:25:09Z",
            "company_name"=>"Aristotle Air Conditioning & Heating",
            "company_id"=>"ae8afda8-3b9d-45d5-a5f2-307b2abb3816",
            "attachments"=>[]
          }
        }
      end
    end
  end
end
