# spec/lib/acceptable_time_spec.rb
# foreman run bundle exec rspec spec/lib/housecall_pro_spec.rb
require 'rails_helper'

describe 'Library: HousecallPro', :special do
  # hcp_client               = Integrations::HousecallPro::Base.new('1996f206ad94156e92af259fdde33e4db7606725a91299d941852b3c4227782d')
  # invalid_hcp_client       = Integrations::HousecallPro::Base.new('asdf')
  # empty_api_key_hcp_client = Integrations::HousecallPro::Base.new()

  ##########
  # Integrations::HousecallPro::Base.company
  ##########
  it 'Test Integrations::HousecallPro::Base.company' do
    expect(hcp_client.company).to eq({
      :id=>"c1f65771-82ea-4722-89df-6144317a30f2",
      :phone_number=>"9098065762",
      :support_email=>"ryan@chiirp.com",
      :name=>"Chiirp",
      :logo_url=>"",
      :address=>{:street=>"4833 Edgewood Dr", :street_line_2=>"", :city=>"Provo", :state=>"UT", :country=>"US", :zip=>"84604", :latitude=>"40.2980219", :longitude=>"-111.6610885"},
      :website=>"http://CHIIRP.com",
      :default_arrival_window=>120,
      :time_zone=>"America/Denver"
    })
    expect(hcp_client.success?).to eq(true)
  end

  it 'Test Integrations::HousecallPro::Base.company with invalid API Key' do
    expect(invalid_hcp_client.company).to eq({:phone_number=>""})
    expect(invalid_hcp_client.success?).to eq(false)
  end

  it 'Test Integrations::HousecallPro::Base.company with empty API Key' do
    expect(empty_api_key_hcp_client.company).to eq({:phone_number=>""})
    expect(empty_api_key_hcp_client.success?).to eq(false)
  end

  ##########
  # Integrations::HousecallPro::Base.company_address
  ##########
  it 'Test Integrations::HousecallPro::Base.company_address' do
    expect(hcp_client.customer_address(customer_id: 'cus_ec9674b7714e4685b2dd1bcc9d78f528', address_id: 'adr_4951f4097c4e42b691fdabc874a739a3')).to eq({
      :address1=>"4841 VT-155",
      :address2=>"",
      :city=>"Mount Holly",
      :state=>"VT",
      :zipcode=>"05758"
    })
    expect(hcp_client.success?).to eq(true)
  end

  it 'Test Integrations::HousecallPro::Base.company_address with invalid address ID' do
    expect(hcp_client.customer_address(customer_id: 'cus_ec9674b7714e4685b2dd1bcc9d78f528', address_id: 'adr_1234')).to eq({})
    expect(hcp_client.success?).to eq(false)
  end

  it 'Test Integrations::HousecallPro::Base.company_address with empty address ID' do
    expect(hcp_client.customer_address(customer_id: 'cus_ec9674b7714e4685b2dd1bcc9d78f528')).to eq({})
    expect(hcp_client.success?).to eq(false)
  end

  it 'Test Integrations::HousecallPro::Base.company_address with invalid customer ID' do
    expect(hcp_client.customer_address(customer_id: 'cus_1234', address_id: 'adr_4951f4097c4e42b691fdabc874a739a3')).to eq({})
    expect(hcp_client.success?).to eq(false)
  end

  it 'Test Integrations::HousecallPro::Base.company_address with empty customer ID' do
    expect(hcp_client.customer_address(address_id: 'adr_4951f4097c4e42b691fdabc874a739a3')).to eq({})
    expect(hcp_client.success?).to eq(false)
  end

  it 'Test Integrations::HousecallPro::Base.company_address with invalid API Key' do
    expect(invalid_hcp_client.customer_address(customer_id: 'cus_ec9674b7714e4685b2dd1bcc9d78f528', address_id: 'adr_4951f4097c4e42b691fdabc874a739a3')).to eq({})
    expect(invalid_hcp_client.success?).to eq(false)
  end

  it 'Test Integrations::HousecallPro::Base.company_address with empty API Key' do
    expect(empty_api_key_hcp_client.customer_address(customer_id: 'cus_ec9674b7714e4685b2dd1bcc9d78f528', address_id: 'adr_4951f4097c4e42b691fdabc874a739a3')).to eq({})
    expect(empty_api_key_hcp_client.success?).to eq(false)
  end

  ##########
  # Integrations::HousecallPro::Base.jobs
  ##########
  it 'Test Integrations::HousecallPro::Base.jobs' do
    expect(hcp_client.jobs(customer_id: 'cus_ec9674b7714e4685b2dd1bcc9d78f528').first).to eq({
      :id=>"job_03984b2f3ad243bc91603bb4ca7d0859",
      :invoice_number=>"16",
      :description=>"Test",
      :customer=>
       {:id=>"cus_ec9674b7714e4685b2dd1bcc9d78f528",
        :first_name=>"Kevin",
        :last_name=>"Neubert",
        :email=>"kevin@kevinneubert.com",
        :mobile_number=>"8023455136",
        :home_number=>nil,
        :work_number=>nil,
        :company=>nil,
        :notifications_enabled=>true,
        :lead_source=>nil,
        :company_name=>"Chiirp",
        :company_id=>"c1f65771-82ea-4722-89df-6144317a30f2",
        :tags=>["Tester", "BillyBob", "TCC"]},
      :address=>{:id=>"adr_4951f4097c4e42b691fdabc874a739a3", :type=>"service", :street=>"4841 VT-155", :street_line_2=>nil, :city=>"Mount Holly", :state=>"VT", :zip=>"05758", :country=>"USA"},
      :note=>nil,
      :work_status=>"scheduled",
      :work_timestamps=>{:on_my_way_at=>nil, :started_at=>nil, :completed_at=>nil},
      :schedule=>{:scheduled_start=>"2022-04-27T13:00:00Z", :scheduled_end=>"2022-04-27T14:00:00Z", :arrival_window=>120},
      :total_amount=>10000,
      :outstanding_balance=>10000,
      :assigned_employees=>
       [{:id=>"pro_72c8ad8a2ad0478d84aa9214fa1e3f77",
         :first_name=>"Test",
         :last_name=>"Tech",
         :email=>"tlrob15@gmail.com",
         :mobile_number=>"9999999999",
         :color_hex=>"0089d1",
         :avatar_url=>"/assets/add_image_thumb.png",
         :role=>"field tech",
         :tags=>[],
         :permissions=>
          {:can_add_and_edit_job=>true,
           :can_be_booked_online=>true,
           :can_call_and_text_with_customers=>true,
           :can_chat_with_customers=>true,
           :can_delete_and_cancel_job=>true,
           :can_edit_message_on_invoice=>true,
           :can_see_street_view_data=>true,
           :can_share_job=>true,
           :can_take_payment_see_prices=>true,
           :can_see_customers=>true,
           :can_see_full_schedule=>true,
           :can_see_future_jobs=>true,
           :can_see_marketing_campaigns=>false,
           :can_see_reporting=>false,
           :can_edit_settings=>true,
           :is_point_of_contact=>false,
           :is_admin=>false},
         :company_name=>"Chiirp",
         :company_id=>"c1f65771-82ea-4722-89df-6144317a30f2"}],
      :tags=>[],
      :original_estimate_id=>nil,
      :lead_source=>nil,
      :company_name=>"Chiirp",
      :company_id=>"c1f65771-82ea-4722-89df-6144317a30f2"
    })
    expect(hcp_client.success?).to eq(true)
  end

  it 'Test Integrations::HousecallPro::Base.jobs with invalid customer ID' do
    expect(hcp_client.jobs(customer_id: 'cus_1234')).to eq([])
    expect(hcp_client.success?).to eq(true)
  end

  it 'Test Integrations::HousecallPro::Base.jobs with empty customer ID' do
    expect(hcp_client.jobs(asdf: 1234).first).to eq({
      :id=>"job_1190e0105b8a479d908ec2888d069ad9",
      :invoice_number=>"133",
      :description=>"",
      :customer=>
       {:id=>"cus_9a21d6b727b84316b43e6c9c7b5f5ffc",
        :first_name=>"JimDandy",
        :last_name=>"Bennett",
        :email=>"jimdandy@kevinneubert.com",
        :mobile_number=>"8025551209",
        :home_number=>nil,
        :work_number=>nil,
        :company=>"JimDandy, Ltd.",
        :notifications_enabled=>true,
        :lead_source=>nil,
        :company_name=>"Chiirp",
        :company_id=>"c1f65771-82ea-4722-89df-6144317a30f2",
        :tags=>["Tester", "New Customer", "Customer", "Chiirp", "EMS", "annualmaint", "November"]},
      :address=>{:id=>"adr_22fe059f6eec4a6f9fc4874929fb3138", :type=>"service", :street=>"100 Main Street", :street_line_2=>"Suite 101", :city=>"Belmont", :state=>"VT", :zip=>"05730", :country=>nil},
      :note=>nil,
      :work_status=>"needs scheduling",
      :work_timestamps=>{:on_my_way_at=>nil, :started_at=>nil, :completed_at=>nil},
      :schedule=>{:scheduled_start=>nil, :scheduled_end=>nil, :arrival_window=>0},
      :total_amount=>0,
      :outstanding_balance=>0,
      :assigned_employees=>[],
      :tags=>[],
      :original_estimate_id=>nil,
      :lead_source=>"Online Booking",
      :company_name=>"Chiirp",
      :company_id=>"c1f65771-82ea-4722-89df-6144317a30f2"
    })
    expect(hcp_client.success?).to eq(true)
  end

  it 'Test Integrations::HousecallPro::Base.jobs with invalid API Key' do
    expect(invalid_hcp_client.jobs(customer_id: 'cus_ec9674b7714e4685b2dd1bcc9d78f528')).to eq([])
    expect(invalid_hcp_client.success?).to eq(false)
  end

  it 'Test Integrations::HousecallPro::Base.jobs with empty API Key' do
    expect(empty_api_key_hcp_client.jobs(customer_id: 'cus_ec9674b7714e4685b2dd1bcc9d78f528')).to eq([])
    expect(empty_api_key_hcp_client.success?).to eq(false)
  end

  ##########
  # Integrations::HousecallPro::Base.jobs_count
  ##########
  it 'Test Integrations::HousecallPro::Base.jobs_count' do
    expect(hcp_client.jobs_count('cus_ec9674b7714e4685b2dd1bcc9d78f528')).to eq(5)
    expect(hcp_client.success?).to eq(true)
  end

  it 'Test Integrations::HousecallPro::Base.jobs_count with invalid customer ID' do
    expect(hcp_client.jobs_count('cus_1234')).to eq(0)
    expect(hcp_client.success?).to eq(true)
  end

  it 'Test Integrations::HousecallPro::base.jobs_count with empty customer ID' do
    expect(hcp_client.jobs_count(nil)).to eq(135)
    expect(hcp_client.success?).to eq(true)
  end

  it 'Test Integrations::HousecallPro::Base.jobs_count with invalid API Key' do
    expect(invalid_hcp_client.jobs_count('cus_ec9674b7714e4685b2dd1bcc9d78f528')).to eq(0)
    expect(invalid_hcp_client.success?).to eq(false)
  end

  it 'Test Integrations::HousecallPro::Base.jobs_count with empty API Key' do
    expect(empty_api_key_hcp_client.jobs_count('cus_ec9674b7714e4685b2dd1bcc9d78f528')).to eq(0)
    expect(empty_api_key_hcp_client.success?).to eq(false)
  end

  ##########
  # Integrations::HousecallPro::Base.customers
  ##########
  it 'Test Integrations::HousecallPro::Base.customers' do
    expect(hcp_client.customers.first).to eq({
      :id=>"cus_2b0bd5ae67de4eecb98e2dafb0a54a88",
      :first_name=>"Taylor",
      :last_name=>"Roberts",
      :email=>nil,
      :mobile_number=>"9517414153",
      :home_number=>nil,
      :work_number=>nil,
      :company=>nil,
      :notifications_enabled=>false,
      :lead_source=>nil,
      :company_name=>"Chiirp",
      :company_id=>"c1f65771-82ea-4722-89df-6144317a30f2",
      :tags=>["Test"],
      :addresses=>[]
    })
    expect(hcp_client.success?).to eq(true)
  end

  it 'Test Integrations::HousecallPro::Base.customers with invalid API Key' do
    expect(invalid_hcp_client.customers).to eq([])
    expect(invalid_hcp_client.success?).to eq(false)
  end

  it 'Test Integrations::HousecallPro::Base.customers with empty API Key' do
    expect(empty_api_key_hcp_client.customers).to eq([])
    expect(empty_api_key_hcp_client.success?).to eq(false)
  end

  ##########
  # Integrations::HousecallPro::Base.customers_count
  ##########
  it 'Test Integrations::HousecallPro::Base.customers_count' do
    expect(hcp_client.customers_count).to eq(9)
    expect(hcp_client.success?).to eq(true)
  end

  it 'Test Integrations::HousecallPro::Base.customers_count with invalid API Key' do
    expect(invalid_hcp_client.customers_count).to eq(0)
    expect(invalid_hcp_client.success?).to eq(false)
  end

  it 'Test Integrations::HousecallPro::Base.customers_count with empty API Key' do
    expect(empty_api_key_hcp_client.customers_count).to eq(0)
    expect(empty_api_key_hcp_client.success?).to eq(false)
  end

  ##########
  # Integrations::HousecallPro::Base.deprovision_webhooks
  ##########
  it 'Test Integrations::HousecallPro::Base.deprovision_webhooks' do
    expect(hcp_client.deprovision_webhooks).to eq(true)
    expect(hcp_client.success?).to eq(true)
  end

  it 'Test Integrations::HousecallPro::Base.deprovision_webhooks with invalid API Key' do
    expect(invalid_hcp_client.deprovision_webhooks).to eq(false)
    expect(invalid_hcp_client.success?).to eq(false)
  end

  it 'Test Integrations::HousecallPro::Base.deprovision_webhooks with empty API Key' do
    expect(empty_api_key_hcp_client.deprovision_webhooks).to eq(false)
    expect(empty_api_key_hcp_client.success?).to eq(false)
  end

  ##########
  # Integrations::HousecallPro::Base.job
  ##########
  it 'Test Integrations::HousecallPro::Base.job' do
    expect(hcp_client.job('job_6767368a9eab456f9713011d321c4cde')).to eq({
      :id=>"job_6767368a9eab456f9713011d321c4cde",
      :invoice_number=>"5",
      :description=>"Carpet Cleaning - Any 3 areas",
      :customer=>
       {:id=>"cus_9a21d6b727b84316b43e6c9c7b5f5ffc",
        :first_name=>"JimDandy",
        :last_name=>"Bennett",
        :email=>"jimdandy@kevinneubert.com",
        :mobile_number=>"8025551209",
        :home_number=>nil,
        :work_number=>nil,
        :company=>"JimDandy, Ltd.",
        :notifications_enabled=>true,
        :lead_source=>nil,
        :company_name=>"Chiirp",
        :company_id=>"c1f65771-82ea-4722-89df-6144317a30f2",
        :tags=>["Tester", "New Customer", "Customer", "Chiirp", "EMS", "annualmaint", "November"]},
      :address=>{:id=>"adr_22fe059f6eec4a6f9fc4874929fb3138", :type=>"service", :street=>"100 Main Street", :street_line_2=>"Suite 101", :city=>"Belmont", :state=>"VT", :zip=>"05730", :country=>nil},
      :note=>"",
      :work_status=>"needs scheduling",
      :work_timestamps=>{:on_my_way_at=>nil, :started_at=>nil, :completed_at=>nil},
      :schedule=>{:scheduled_start=>nil, :scheduled_end=>nil, :arrival_window=>0},
      :total_amount=>2000,
      :outstanding_balance=>2000,
      :assigned_employees=>
       [{:id=>"pro_6dfa336aa6be48a4bc5a6fd570304a2e",
         :first_name=>"Kevin",
         :last_name=>"Neubert",
         :email=>"kevin@kevinneubert.com",
         :mobile_number=>"8023455136",
         :color_hex=>"03579b",
         :avatar_url=>"/assets/add_image_thumb.png",
         :role=>"field tech",
         :tags=>[],
         :permissions=>
          {:can_add_and_edit_job=>true,
           :can_be_booked_online=>true,
           :can_call_and_text_with_customers=>true,
           :can_chat_with_customers=>true,
           :can_delete_and_cancel_job=>true,
           :can_edit_message_on_invoice=>true,
           :can_see_street_view_data=>true,
           :can_share_job=>true,
           :can_take_payment_see_prices=>true,
           :can_see_customers=>true,
           :can_see_full_schedule=>true,
           :can_see_future_jobs=>true,
           :can_see_marketing_campaigns=>false,
           :can_see_reporting=>true,
           :can_edit_settings=>true,
           :is_point_of_contact=>false,
           :is_admin=>true},
         :company_name=>"Chiirp",
         :company_id=>"c1f65771-82ea-4722-89df-6144317a30f2"}],
      :tags=>["Needs Rescheduling"],
      :original_estimate_id=>nil,
      :lead_source=>nil,
      :company_name=>"Chiirp",
      :company_id=>"c1f65771-82ea-4722-89df-6144317a30f2"
    })
    expect(hcp_client.success?).to eq(true)
  end

  it 'Test Integrations::HousecallPro::Base.job with invalid job ID' do
    expect(hcp_client.job('job_1234')).to eq({})
    expect(hcp_client.success?).to eq(false)
  end

  it 'Test Integrations::HousecallPro::Base.job with empty job ID' do
    expect(hcp_client.job(0)).to eq({})
    expect(hcp_client.success?).to eq(false)
  end

  it 'Test Integrations::HousecallPro::Base.job with invalid API Key' do
    expect(invalid_hcp_client.job('job_6767368a9eab456f9713011d321c4cde')).to eq({})
    expect(invalid_hcp_client.success?).to eq(false)
  end

  it 'Test Integrations::HousecallPro::Base.job with empty API Key' do
    expect(empty_api_key_hcp_client.job('job_6767368a9eab456f9713011d321c4cde')).to eq({})
    expect(empty_api_key_hcp_client.success?).to eq(false)
  end

  ##########
  # Integrations::HousecallPro::Base.job_line_items
  ##########
  it 'Test Integrations::HousecallPro::Base.job_line_items' do
    expect(hcp_client.job_line_items('job_6767368a9eab456f9713011d321c4cde').first).to eq({
      :id=>"olit_749a2d2712be4666a3904b106ded9181",
      :name=>"Carpet Cleaning - Any 3 areas"
    })
    expect(hcp_client.success?).to eq(true)
  end

  it 'Test Integrations::HousecallPro::Base.job_line_items with invalid job ID' do
    expect(hcp_client.job_line_items('job_1234')).to eq([])
    expect(hcp_client.success?).to eq(false)
  end

  it 'Test Integrations::HousecallPro::Base.job_line_items with empty job ID' do
    expect(hcp_client.job_line_items(0)).to eq([])
    expect(hcp_client.success?).to eq(false)
  end

  it 'Test Integrations::HousecallPro::Base.job_line_items with invalid API Key' do
    expect(invalid_hcp_client.job_line_items('job_6767368a9eab456f9713011d321c4cde')).to eq([])
    expect(invalid_hcp_client.success?).to eq(false)
  end

  it 'Test Integrations::HousecallPro::Base.job_line_items with empty API Key' do
    expect(empty_api_key_hcp_client.job_line_items('job_6767368a9eab456f9713011d321c4cde')).to eq([])
    expect(empty_api_key_hcp_client.success?).to eq(false)
  end

  ##########
  # Integrations::HousecallPro::Base.technician
  ##########
  it 'Test Integrations::HousecallPro::Base.technician' do
    expect(hcp_client.technician('pro_fac7f76b125b4315a2c0d1f2015360d0')).to eq({
      :id=>"pro_fac7f76b125b4315a2c0d1f2015360d0",
      :first_name=>"Taylor",
      :last_name=>"Roberts",
      :email=>"taylor@chiirp.com",
      :mobile_number=>"9517414153",
      :color_hex=>"0297a7",
      :avatar_url=>"/assets/add_image_thumb.png",
      :role=>"field tech",
      :tags=>[],
      :permissions=>
       {:can_add_and_edit_job=>true,
        :can_be_booked_online=>true,
        :can_call_and_text_with_customers=>true,
        :can_chat_with_customers=>true,
        :can_delete_and_cancel_job=>true,
        :can_edit_message_on_invoice=>true,
        :can_see_street_view_data=>true,
        :can_share_job=>true,
        :can_take_payment_see_prices=>true,
        :can_see_customers=>true,
        :can_see_full_schedule=>true,
        :can_see_future_jobs=>true,
        :can_see_marketing_campaigns=>false,
        :can_see_reporting=>true,
        :can_edit_settings=>true,
        :is_point_of_contact=>true,
        :is_admin=>true},
      :company_name=>"Chiirp",
      :company_id=>"c1f65771-82ea-4722-89df-6144317a30f2"
    })
    expect(hcp_client.success?).to eq(true)
  end

  it 'Test Integrations::HousecallPro::Base.technician with invalid technician ID' do
    expect(hcp_client.technician('pro_1234')).to eq({})
    expect(hcp_client.success?).to eq(false)
  end

  it 'Test Integrations::HousecallPro::Base.technician with empty technician ID' do
    expect(hcp_client.technician(0)).to eq({})
    expect(hcp_client.success?).to eq(false)
  end

  it 'Test Integrations::HousecallPro::Base.technician with invalid API Key' do
    expect(invalid_hcp_client.technician('pro_fac7f76b125b4315a2c0d1f2015360d0')).to eq({})
    expect(invalid_hcp_client.success?).to eq(false)
  end

  it 'Test Integrations::HousecallPro::Base.technician with empty API Key' do
    expect(empty_api_key_hcp_client.technician('pro_fac7f76b125b4315a2c0d1f2015360d0')).to eq({})
    expect(empty_api_key_hcp_client.success?).to eq(false)
  end

  ##########
  # Integrations::HousecallPro::Base.technicians
  ##########
  it 'Test Integrations::HousecallPro::Base.technicians' do
    expect(hcp_client.technicians.last).to eq({
      :name=>"Ryan Fenn",
      :id=>"pro_76d0a1ff8d174ce381d1e75f6bcf9e92",
      :phone=>"9098065762",
      :email=>"ryan@chiirp.com"
    })
    expect(hcp_client.success?).to eq(true)
  end

  it 'Test Integrations::HousecallPro::Base.technicians(page_size: 2)' do
    expect(hcp_client.technicians.last).to eq({
      :name=>"Ryan Fenn",
      :id=>"pro_76d0a1ff8d174ce381d1e75f6bcf9e92",
      :phone=>"9098065762",
      :email=>"ryan@chiirp.com"
    })
    expect(hcp_client.success?).to eq(true)
  end

  it 'Test Integrations::HousecallPro::Base.technicians with invalid API Key' do
    expect(invalid_hcp_client.technicians).to eq([])
    expect(invalid_hcp_client.success?).to eq(false)
  end

  it 'Test Integrations::HousecallPro::Base.technicians with empty API Key' do
    expect(empty_api_key_hcp_client.technicians).to eq([])
    expect(empty_api_key_hcp_client.success?).to eq(false)
  end

  ##########
  # Integrations::HousecallPro::Base.parse_job_from_webhook
  ##########
  test_job = {
    :id=>"job_6767368a9eab456f9713011d321c4cde",
    :invoice_number=>"5",
    :description=>"Carpet Cleaning - Any 3 areas",
    :customer=>
     {:id=>"cus_9a21d6b727b84316b43e6c9c7b5f5ffc",
      :first_name=>"JimDandy",
      :last_name=>"Bennett",
      :email=>"jimdandy@kevinneubert.com",
      :mobile_number=>"8025551209",
      :home_number=>nil,
      :work_number=>nil,
      :company=>"JimDandy, Ltd.",
      :notifications_enabled=>true,
      :lead_source=>nil,
      :company_name=>"Chiirp",
      :company_id=>"c1f65771-82ea-4722-89df-6144317a30f2",
      :tags=>["Tester", "New Customer", "Customer", "Chiirp", "EMS", "annualmaint", "November"]},
    :address=>{:id=>"adr_22fe059f6eec4a6f9fc4874929fb3138", :type=>"service", :street=>"100 Main Street", :street_line_2=>"Suite 101", :city=>"Belmont", :state=>"VT", :zip=>"05730", :country=>nil},
    :note=>"",
    :work_status=>"needs scheduling",
    :work_timestamps=>{:on_my_way_at=>nil, :started_at=>nil, :completed_at=>nil},
    :schedule=>{:scheduled_start=>nil, :scheduled_end=>nil, :arrival_window=>0},
    :total_amount=>2000,
    :outstanding_balance=>2000,
    :assigned_employees=>
     [{:id=>"pro_6dfa336aa6be48a4bc5a6fd570304a2e",
       :first_name=>"Kevin",
       :last_name=>"Neubert",
       :email=>"kevin@kevinneubert.com",
       :mobile_number=>"8023455136",
       :color_hex=>"03579b",
       :avatar_url=>"/assets/add_image_thumb.png",
       :role=>"field tech",
       :tags=>[],
       :permissions=>
        {:can_add_and_edit_job=>true,
         :can_be_booked_online=>true,
         :can_call_and_text_with_customers=>true,
         :can_chat_with_customers=>true,
         :can_delete_and_cancel_job=>true,
         :can_edit_message_on_invoice=>true,
         :can_see_street_view_data=>true,
         :can_share_job=>true,
         :can_take_payment_see_prices=>true,
         :can_see_customers=>true,
         :can_see_full_schedule=>true,
         :can_see_future_jobs=>true,
         :can_see_marketing_campaigns=>false,
         :can_see_reporting=>true,
         :can_edit_settings=>true,
         :is_point_of_contact=>false,
         :is_admin=>true},
       :company_name=>"Chiirp",
       :company_id=>"c1f65771-82ea-4722-89df-6144317a30f2"}],
    :tags=>["Needs Rescheduling"],
    :original_estimate_id=>nil,
    :lead_source=>nil,
    :company_name=>"Chiirp",
    :company_id=>"c1f65771-82ea-4722-89df-6144317a30f2"
  }

  it 'Test Integrations::HousecallPro::Base.parse_job_from_webhook' do
    expect(hcp_client.parse_job_from_webhook(job: test_job)).to eq({
      :id=>"job_6767368a9eab456f9713011d321c4cde",
      :number=>"5",
      :name=>"",
      :description=>"Carpet Cleaning - Any 3 areas",
      :total_amount=>0.2e2,
      :outstanding_balance=>0.2e2,
      :status=>"needs scheduling",
      :scheduled=>{:start_at=>"", :end_at=>"", :arrival_window=>"0"},
      :actual=>{:started_at=>"", :completed_at=>"", :on_my_way_at=>""},
      :notes=>"",
      :invoice_number=>"5",
      :original_estimate=>{:id=>""}
    })
  end

  it 'Test Integrations::HousecallPro::Base.parse_job_from_webhook with empty API Key' do
    expect(empty_api_key_hcp_client.parse_job_from_webhook(job: empty_api_key_hcp_client.job('job_6767368a9eab456f9713011d321c4cde'))).to eq({
      :id=>"",
      :number=>"",
      :name=>"",
      :description=>"",
      :total_amount=>0.0,
      :outstanding_balance=>0.0,
      :status=>"",
      :scheduled=>{:start_at=>"", :end_at=>"", :arrival_window=>""},
      :actual=>{:started_at=>"", :completed_at=>"", :on_my_way_at=>""},
      :notes=>"",
      :invoice_number=>"",
      :original_estimate=>{:id=>""}
    })
  end

  it 'Test Integrations::HousecallPro::Base.parse_job_from_webhook with missing data' do
    expect(hcp_client.parse_job_from_webhook).to eq({
      :id=>"",
      :number=>"",
      :name=>"",
      :description=>"",
      :total_amount=>0.0,
      :outstanding_balance=>0.0,
      :status=>"",
      :scheduled=>{:start_at=>"", :end_at=>"", :arrival_window=>""},
      :actual=>{:started_at=>"", :completed_at=>"", :on_my_way_at=>""},
      :notes=>"",
      :invoice_number=>"",
      :original_estimate=>{:id=>""}
    })
  end

  it 'Test Integrations::HousecallPro::Base.parse_job_from_webhook with invalid data' do
    expect(hcp_client.parse_job_from_webhook(job: {})).to eq({
      :id=>"",
      :number=>"",
      :name=>"",
      :description=>"",
      :total_amount=>0.0,
      :outstanding_balance=>0.0,
      :status=>"",
      :scheduled=>{:start_at=>"", :end_at=>"", :arrival_window=>""},
      :actual=>{:started_at=>"", :completed_at=>"", :on_my_way_at=>""},
      :notes=>"",
      :invoice_number=>"",
      :original_estimate=>{:id=>""}
    })
  end

  ##########
  # Integrations::HousecallPro::ParseWebhook
  ##########
  estimate_created_data = {
    event: "estimate.created",
    company_id: "c1f65771-82ea-4722-89df-6144317a30f2",
    estimate: {
      :id=>"csr_24fb77731ef6449c936475bcedf373b2",
      :estimate_number=>"2",
      :work_status=>"pro canceled",
      :lead_source=>nil,
      :customer=>
      {
        :id=>"cus_ec9674b7714e4685b2dd1bcc9d78f528",
        :first_name=>"Kevin",
        :last_name=>"Neubert",
        :email=>"kevin@kevinneubert.com",
        :mobile_number=>"8023455136",
        :home_number=>nil,
        :work_number=>nil,
        :company=>nil,
        :notifications_enabled=>true,
        :lead_source=>nil,
        :company_name=>"Chiirp",
        :company_id=>"c1f65771-82ea-4722-89df-6144317a30f2",
        :tags=>["Tester", "BillyBob", "TCC"]
      },
      :address=>{:id=>"adr_4951f4097c4e42b691fdabc874a739a3", :type=>"service", :street=>"4841 VT-155", :street_line_2=>nil, :city=>"Mount Holly", :state=>"VT", :zip=>"05758", :country=>"USA"},
      :company_name=>"Chiirp",
      :company_id=>"c1f65771-82ea-4722-89df-6144317a30f2",
      :work_timestamps=>{:on_my_way_at=>nil, :started_at=>nil, :completed_at=>nil},
      :schedule=>{:scheduled_start=>nil, :scheduled_end=>nil, :arrival_window=>0},
      :assigned_employees=>
      [
        {
          :id=>"pro_72c8ad8a2ad0478d84aa9214fa1e3f77",
          :first_name=>"Test",
          :last_name=>"Tech",
          :email=>"tlrob15@gmail.com",
          :mobile_number=>"9999999999",
          :color_hex=>"0089d1",
          :avatar_url=>"/assets/add_image_thumb.png",
          :role=>"field tech",
          :tags=>[],
          :permissions=>
          {
            :can_add_and_edit_job=>true,
            :can_be_booked_online=>true,
            :can_call_and_text_with_customers=>true,
            :can_chat_with_customers=>true,
            :can_delete_and_cancel_job=>true,
            :can_edit_message_on_invoice=>true,
            :can_see_street_view_data=>true,
            :can_share_job=>true,
            :can_take_payment_see_prices=>true,
            :can_see_customers=>true,
            :can_see_full_schedule=>true,
            :can_see_future_jobs=>true,
            :can_see_marketing_campaigns=>false,
            :can_see_reporting=>false,
            :can_edit_settings=>true,
            :is_point_of_contact=>false,
            :is_admin=>false
          },
          :company_name=>"Chiirp",
          :company_id=>"c1f65771-82ea-4722-89df-6144317a30f2"
        }
      ],
      :options=>
      [
        {:id=>"est_7f9ad9d81fd84841938ecb9e580db7cf", :name=>"Option #1", :option_number=>"2", :total_amount=>1000, :approval_status=>"pro approved", :message_from_pro=>nil},
        {:id=>"est_3316d7c737ba46c392fca1c814c90c35", :name=>"Option #2", :option_number=>"2", :total_amount=>2000, :approval_status=>"declined", :message_from_pro=>nil},
        {:id=>"est_c9bba7ca14c144668f84dc5dec375abf", :name=>"Option #3", :option_number=>"2", :total_amount=>3000, :approval_status=>"declined", :message_from_pro=>nil}
      ]
    }
  }

  it 'Test Integrations::HousecallPro::ParseWebhook with estimate.created' do
    expect(hcp_client.parse_webhook(estimate_created_data)).to eq({
      :event=>"estimate.created",
      :company_id=>"c1f65771-82ea-4722-89df-6144317a30f2",
      :contact=>{:customer_id=>"cus_ec9674b7714e4685b2dd1bcc9d78f528", :lastname=>"Neubert", :firstname=>"Kevin", :email=>"kevin@kevinneubert.com", :companyname=>"", :lead_source=>""},
      :address=>{:id=>"adr_4951f4097c4e42b691fdabc874a739a3", :address_01=>"4841 VT-155", :address_02=>"", :city=>"Mount Holly", :state=>"VT", :postal_code=>"05758", :country=>"USA"},
      :contact_phones=>{"8023455136"=>"mobile"},
      :tags=>["Tester", "BillyBob", "TCC"],
      :job=>
      {
        :id=>"",
        :number=>"",
        :name=>"",
        :description=>"",
        :total_amount=>0.0,
        :outstanding_balance=>0.0,
        :status=>"",
        :scheduled=>{:start_at=>"", :end_at=>"", :arrival_window=>""},
        :actual=>{:started_at=>"", :completed_at=>"", :on_my_way_at=>""},
        :notes=>"",
        :invoice_number=>"",
        :original_estimate=>{:id=>""}
      },
      :estimate=>
      {
        :id=>"csr_24fb77731ef6449c936475bcedf373b2",
        :number=>"2",
        :status=>"pro canceled",
        :scheduled=>{:start_at=>"", :end_at=>"", :arrival_window=>"0"},
        :actual=>{:started_at=>"", :completed_at=>"", :on_my_way_at=>""},
        :options=>
        [
          {:id=>"est_7f9ad9d81fd84841938ecb9e580db7cf", :name=>"Option #1", :option_number=>"2", :total_amount=>"1000", :approval_status=>"pro approved", :message=>""},
          {:id=>"est_3316d7c737ba46c392fca1c814c90c35", :name=>"Option #2", :option_number=>"2", :total_amount=>"2000", :approval_status=>"declined", :message=>""},
          {:id=>"est_c9bba7ca14c144668f84dc5dec375abf", :name=>"Option #3", :option_number=>"2", :total_amount=>"3000", :approval_status=>"declined", :message=>""}
        ]
      },
      :technician=>{:id=>"pro_72c8ad8a2ad0478d84aa9214fa1e3f77", :firstname=>"Test", :lastname=>"Tech", :name=>"Test Tech", :email=>"tlrob15@gmail.com", :phone=>"9999999999", :role=>"field tech"}
    })
  end

  it 'Test Integrations::HousecallPro::ParseWebhook with estimate.created with empty API Key' do
    expect(empty_api_key_hcp_client.parse_webhook(estimate_created_data)).to eq({
      :event=>"estimate.created",
      :company_id=>"c1f65771-82ea-4722-89df-6144317a30f2",
      :contact=>{:customer_id=>"cus_ec9674b7714e4685b2dd1bcc9d78f528", :lastname=>"Neubert", :firstname=>"Kevin", :email=>"kevin@kevinneubert.com", :companyname=>"", :lead_source=>""},
      :address=>{:id=>"adr_4951f4097c4e42b691fdabc874a739a3", :address_01=>"4841 VT-155", :address_02=>"", :city=>"Mount Holly", :state=>"VT", :postal_code=>"05758", :country=>"USA"},
      :contact_phones=>{"8023455136"=>"mobile"},
      :tags=>["Tester", "BillyBob", "TCC"],
      :job=>
      {
        :id=>"",
        :number=>"",
        :name=>"",
        :description=>"",
        :total_amount=>0.0,
        :outstanding_balance=>0.0,
        :status=>"",
        :scheduled=>{:start_at=>"", :end_at=>"", :arrival_window=>""},
        :actual=>{:started_at=>"", :completed_at=>"", :on_my_way_at=>""},
        :notes=>"",
        :invoice_number=>"",
        :original_estimate=>{:id=>""}
      },
      :estimate=>
      {
        :id=>"csr_24fb77731ef6449c936475bcedf373b2",
        :number=>"2",
        :status=>"pro canceled",
        :scheduled=>{:start_at=>"", :end_at=>"", :arrival_window=>"0"},
        :actual=>{:started_at=>"", :completed_at=>"", :on_my_way_at=>""},
        :options=>
        [
          {:id=>"est_7f9ad9d81fd84841938ecb9e580db7cf", :name=>"Option #1", :option_number=>"2", :total_amount=>"1000", :approval_status=>"pro approved", :message=>""},
          {:id=>"est_3316d7c737ba46c392fca1c814c90c35", :name=>"Option #2", :option_number=>"2", :total_amount=>"2000", :approval_status=>"declined", :message=>""},
          {:id=>"est_c9bba7ca14c144668f84dc5dec375abf", :name=>"Option #3", :option_number=>"2", :total_amount=>"3000", :approval_status=>"declined", :message=>""}
        ]
      },
      :technician=>{:id=>"pro_72c8ad8a2ad0478d84aa9214fa1e3f77", :firstname=>"Test", :lastname=>"Tech", :name=>"Test Tech", :email=>"tlrob15@gmail.com", :phone=>"9999999999", :role=>"field tech"}
    })
  end

  estimate_scheduled_data = {
    event: "estimate.scheduled",
    company_id: "c1f65771-82ea-4722-89df-6144317a30f2",
    estimate: {
      id: "csr_24fb77731ef6449c936475bcedf373b2",
      estimate_number: "2",
      work_status: "needs scheduling",
      customer: {
        id: "cus_70c00960c6fa41eabc9a52a5933437c6",
        first_name: "Kevin",
        last_name: "Neubert",
        email: "kevin@kevinneubert.com",
        mobile_number: "8023455136",
        home_number: nil,
        work_number: nil,
        company: nil,
        notifications_enabled: true,
        tags: ["Residential", "new door"]
      },
      address: {
        id: "adr_fec2485d24154fdda6e16a7e93bbada1",
        type: "billing",
        street: "4841 VT-155",
        street_line_2: nil,
        city: "Belmont",
        state: "VT",
        zip: "05730",
        country: "US"
      },
      work_timestamps: {
        on_my_way_at: nil,
        started_at: nil,
        completed_at: nil
      },
      schedule: {
        scheduled_start: "2022-02-28T18:00:00Z", 
        scheduled_end: "2022-02-28T20:00:00Z", 
        arrival_window: 0
      },
      assigned_employees: [
        {
          id: "pro_6dfa336aa6be48a4bc5a6fd570304a2e",
          first_name: "Kevin",
          last_name: "Neubert",
          email: "kevin@kevinneubert.com",
          mobile_number: "8023455136",
          color_hex: "03579b",
          avatar_url: "https://housecall-attachments-production.s3.amazonaws.com/service_pros/avatars/000/406/870/thumb/avatar_1637427493.png?1637427493",
          role: "field tech",
          tags: [],
          permissions: {
            can_add_and_edit_job: true,
            can_be_booked_online: true,
            can_call_and_text_with_customers: true,
            can_chat_with_customers: true,
            can_delete_and_cancel_job: true,
            can_edit_message_on_invoice: true,
            can_see_street_view_data: true,
            can_share_job: true,
            can_take_payment_see_prices: true,
            can_see_customers: true,
            can_see_full_schedule: true,
            can_see_future_jobs: true,
            can_see_marketing_campaigns: true,
            can_see_reporting: true,
            can_edit_settings: true,
            is_point_of_contact: false,
            is_admin: true
          }
        }
      ],
      options: [
        {
          id: "est_7f9ad9d81fd84841938ecb9e580db7cf", 
          name: "Option #1", 
          option_number: "1", 
          total_amount: 0, 
          approval_status: nil, 
          message_from_pro: "Thank you!"
        },
        {
          id: "est_3316d7c737ba46c392fca1c814c90c35", 
          name: "Option #2", 
          option_number: "2", 
          total_amount: 0, 
          approval_status: nil, 
          message_from_pro: "Thank you!"
        }
      ]
    }
  }

  it 'Test Integrations::HousecallPro::ParseWebhook with estimate.scheduled' do
    expect(hcp_client.parse_webhook(estimate_scheduled_data)).to eq({
      :event=>"estimate.scheduled",
      :company_id=>"c1f65771-82ea-4722-89df-6144317a30f2",
      :contact=>{:customer_id=>"cus_70c00960c6fa41eabc9a52a5933437c6", :lastname=>"Neubert", :firstname=>"Kevin", :email=>"kevin@kevinneubert.com", :companyname=>"", :lead_source=>""},
      :address=>{:id=>"adr_fec2485d24154fdda6e16a7e93bbada1", :address_01=>"4841 VT-155", :address_02=>"", :city=>"Belmont", :state=>"VT", :postal_code=>"05730", :country=>"US"},
      :contact_phones=>{"8023455136"=>"mobile"},
      :tags=>["Residential", "new door"],
      :job=>
      {
        :id=>"",
        :number=>"",
        :name=>"",
        :description=>"",
        :total_amount=>0.0,
        :outstanding_balance=>0.0,
        :status=>"",
        :scheduled=>{:start_at=>"", :end_at=>"", :arrival_window=>""},
        :actual=>{:started_at=>"", :completed_at=>"", :on_my_way_at=>""},
        :notes=>"",
        :invoice_number=>"",
        :original_estimate=>{:id=>""}
      },
      :estimate=>
      {
        :id=>"csr_24fb77731ef6449c936475bcedf373b2",
        :number=>"2",
        :status=>"needs scheduling",
        :scheduled=>{:start_at=>"2022-02-28T18:00:00Z", :end_at=>"2022-02-28T20:00:00Z", :arrival_window=>"0"},
        :actual=>{:started_at=>"", :completed_at=>"", :on_my_way_at=>""},
        :options=>
        [
          {:id=>"est_7f9ad9d81fd84841938ecb9e580db7cf", :name=>"Option #1", :option_number=>"1", :total_amount=>"0", :approval_status=>"", :message=>""},
          {:id=>"est_3316d7c737ba46c392fca1c814c90c35", :name=>"Option #2", :option_number=>"2", :total_amount=>"0", :approval_status=>"", :message=>""}
        ]
      },
      :technician=>{:id=>"pro_6dfa336aa6be48a4bc5a6fd570304a2e", :firstname=>"Kevin", :lastname=>"Neubert", :name=>"Kevin Neubert", :email=>"kevin@kevinneubert.com", :phone=>"8023455136", :role=>"field tech"}
    })
  end

  it 'Test Integrations::HousecallPro::ParseWebhook with estimate.scheduled with empty API Key' do
    expect(empty_api_key_hcp_client.parse_webhook(estimate_scheduled_data)).to eq({
      :event=>"estimate.scheduled",
      :company_id=>"c1f65771-82ea-4722-89df-6144317a30f2",
      :contact=>{:customer_id=>"cus_70c00960c6fa41eabc9a52a5933437c6", :lastname=>"Neubert", :firstname=>"Kevin", :email=>"kevin@kevinneubert.com", :companyname=>"", :lead_source=>""},
      :address=>{:id=>"adr_fec2485d24154fdda6e16a7e93bbada1", :address_01=>"4841 VT-155", :address_02=>"", :city=>"Belmont", :state=>"VT", :postal_code=>"05730", :country=>"US"},
      :contact_phones=>{"8023455136"=>"mobile"},
      :tags=>["Residential", "new door"],
      :job=>
      {
        :id=>"",
        :number=>"",
        :name=>"",
        :description=>"",
        :total_amount=>0.0,
        :outstanding_balance=>0.0,
        :status=>"",
        :scheduled=>{:start_at=>"", :end_at=>"", :arrival_window=>""},
        :actual=>{:started_at=>"", :completed_at=>"", :on_my_way_at=>""},
        :notes=>"",
        :invoice_number=>"",
        :original_estimate=>{:id=>""}
      },
      :estimate=>
      {
        :id=>"csr_24fb77731ef6449c936475bcedf373b2",
        :number=>"2",
        :status=>"needs scheduling",
        :scheduled=>{:start_at=>"2022-02-28T18:00:00Z", :end_at=>"2022-02-28T20:00:00Z", :arrival_window=>"0"},
        :actual=>{:started_at=>"", :completed_at=>"", :on_my_way_at=>""},
        :options=>
        [
          {:id=>"est_7f9ad9d81fd84841938ecb9e580db7cf", :name=>"Option #1", :option_number=>"1", :total_amount=>"0", :approval_status=>"", :message=>""},
          {:id=>"est_3316d7c737ba46c392fca1c814c90c35", :name=>"Option #2", :option_number=>"2", :total_amount=>"0", :approval_status=>"", :message=>""}
        ]
      },
      :technician=>{:id=>"pro_6dfa336aa6be48a4bc5a6fd570304a2e", :firstname=>"Kevin", :lastname=>"Neubert", :name=>"Kevin Neubert", :email=>"kevin@kevinneubert.com", :phone=>"8023455136", :role=>"field tech"}
    })
  end

  ##########
  # Integrations::HousecallPro::Base.provision_webhooks
  ##########
  it 'Test Integrations::HousecallPro::Base.provision_webhooks' do
    expect(hcp_client.provision_webhooks).to eq(true)
    expect(hcp_client.success?).to eq(true)
  end

  it 'Test Integrations::HousecallPro::Base.provision_webhooks with invalid API Key' do
    expect(invalid_hcp_client.provision_webhooks).to eq(false)
    expect(invalid_hcp_client.success?).to eq(false)
  end

  it 'Test Integrations::HousecallPro::Base.provision_webhooks with empty API Key' do
    expect(empty_api_key_hcp_client.provision_webhooks).to eq(false)
    expect(empty_api_key_hcp_client.success?).to eq(false)
  end
end
