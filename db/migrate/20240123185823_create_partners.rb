class CreatePartners < ActiveRecord::Migration[7.1]
  def up
    ActiveRecord::Base.record_timestamps = false
    say 'Turned off timestamps.'

    say_with_time 'Renaming Partners table to Affiliates...' do
  		rename_table   :partners, :affiliates
    end

    say_with_time 'Creating Integrations table...' do
      create_table :integrations do |t|
        t.string  :company_name
        t.boolean :show_company_name, default: true
        t.string  :contact
        t.string  :short_description
        t.text    :description
        t.string  :phone_number
        t.boolean :preferred, default: false
        t.integer :sort_order, default: 0
        t.string  :website_url
        t.string  :image_url
        t.string  :youtube_url
        t.string  :controller
        t.string  :integration
        t.string  :link_url

        t.timestamps
      end
    end

    say_with_time 'Populating Integrations table...' do
      ActiveRecord::Base.record_timestamps = true
      SystemSettings::Integration.create(company_name: 'TrustedForm', short_description: 'Generate Certified Leads easily and FREE!', show_company_name: true, controller: 'integrations_user', integration: 'activeprospect', link_url: '/integrations/activeprospect/integration')
      SystemSettings::Integration.create(company_name: 'Calendly', short_description: 'Schedule meetings without the back-and-forth emails!', show_company_name: false, controller: 'integrations_user', integration: 'calendly', link_url: '/integrations/calendly/integration')
      SystemSettings::Integration.create(company_name: 'CallRail', short_description: 'Handle incoming phone calls with ease!', show_company_name: false, controller: 'integrations_user', integration: 'callrail', link_url: '/integrations/callrail/v3')
      SystemSettings::Integration.create(company_name: 'CardX', short_description: 'Accept credit cards at 0% cost. Achieve automated compliance.', show_company_name: false, controller: 'integrations_user', integration: 'cardx', link_url: '/integrations/cardx')
      SystemSettings::Integration.create(company_name: 'Dope Marketing', short_description: 'Neighborhood Blitz - Send Automated Postcards to Neighbors!', show_company_name: true, controller: 'integrations_client', integration: 'dope_marketing', link_url: '/integrations/dope/v1/integration')
      SystemSettings::Integration.create(company_name: 'DropFunnels', short_description: 'The Elite Marketer\'s Choice!', show_company_name: true, controller: 'integrations_client', integration: 'dropfunnels', link_url: '/integrations/dropfunnels/integration')
      SystemSettings::Integration.create(company_name: 'Email', short_description: 'Send emails from your Chiirp account.', show_company_name: true, controller: 'integrations_user', integration: 'email', link_url: '/integrations/email/v1')
      SystemSettings::Integration.create(company_name: 'Facebook', short_description: 'Connect to Facebook to collect your Leads and use Messenger!', show_company_name: true, controller: 'integrations_user', integration: 'facebook_leads', link_url: '/integrations/facebook/integration')
      SystemSettings::Integration.create(company_name: 'Five9', short_description: 'Connect your Five9 account, reimagine CX and realize results!', show_company_name: true, controller: 'integrations_client', integration: 'five9', link_url: '/integrations/five9/integration')
      SystemSettings::Integration.create(company_name: 'Google', short_description: 'Connect to Google for dashboard calendars!', show_company_name: true, controller: 'integrations_user', integration: 'google', link_url: '/integrations/google/integrations')
      SystemSettings::Integration.create(company_name: 'Housecall Pro', short_description: 'Connect your Housecall Pro account and convert more leads into customers!', show_company_name: false, controller: 'integrations_client', integration: 'housecall', link_url: '/integrations/housecall')
      SystemSettings::Integration.create(company_name: 'Interest Rates', short_description: 'Automatically alert your leads based on current interest rates!', show_company_name: true, controller: 'integrations_client', integration: 'interest_rates', link_url: '/integrations/interest_rates/integration/edit')
      SystemSettings::Integration.create(company_name: 'Jobber', short_description: 'Connect your Jobber account and your customers will love you even more!', show_company_name: false, controller: 'integrations_client', integration: 'jobber', link_url: '/integrations/jobber')
      SystemSettings::Integration.create(company_name: 'JobNimbus', short_description: 'Connect your JobNimbus account and keep your leads & customers informed!', show_company_name: false, controller: 'integrations_client', integration: 'jobnimbus', link_url: '/integrations/jobnimbus')
      SystemSettings::Integration.create(company_name: 'JotForm', short_description: 'Connect to JotForm and receive your leads in real time!', show_company_name: false, controller: 'integrations_user', integration: 'jotform', link_url: '/integrations/jotform/integration')
      SystemSettings::Integration.create(company_name: 'Maestro', short_description: 'Connect your Maestro account and text your Guests before, during & after their stay!', show_company_name: false, controller: 'integrations_client', integration: 'maestro', link_url: '/integrations/maestro')
      SystemSettings::Integration.create(company_name: 'OutReach', short_description: 'Connect with The Engagement & Intelligence Platform!', show_company_name: false, controller: 'integrations_user', integration: 'outreach', link_url: '/integrations/outreach/integration')
      SystemSettings::Integration.create(company_name: 'PC Richards', short_description: 'Connect with PC Richard to received & submit product installations!', show_company_name: false, controller: 'integrations_client', integration: 'pcrichard', link_url: '/integrations/pcrichard/v1')
      SystemSettings::Integration.create(company_name: 'PhoneSites', short_description: 'Connect your PhoneSites Websites and receive your leads in real time!', show_company_name: false, controller: 'integrations_user', integration: 'phone_sites', link_url: '/integrations/phone_sites/integration')
      SystemSettings::Integration.create(company_name: 'ResponsiBid', short_description: 'Close Bids Faster & Easier with Automated Follow-Up!', show_company_name: false, controller: 'integrations_user', integration: 'responsibid', link_url: '/integrations/responsibid')
      SystemSettings::Integration.create(company_name: 'SalesRabbit', short_description: 'Connect your SalesRabbit account and start texting your new Leads immediately!', show_company_name: true, controller: 'integrations_client', integration: 'salesrabbit', link_url: '/integrations/salesrabbit/integration/edit')
      SystemSettings::Integration.create(company_name: 'SearchLight', short_description: 'Visually connect Campaigns to customer revenue!', show_company_name: false, controller: 'integrations_client', integration: 'searchlight', link_url: '/integrations/searchlight/v1')
      SystemSettings::Integration.create(company_name: 'SendGrid', short_description: 'Connect your SendGrid account and start emailing your new Contacts immediately!', show_company_name: false, controller: 'integrations_client', integration: 'sendgrid', link_url: '/integrations/sendgrid/v1')
      SystemSettings::Integration.create(company_name: 'SendJim', short_description: 'Automate post cards to neighbors, post card reminders, handwritten cards, gifts and more by adding SendJim to campaigns.', show_company_name: false, controller: 'integrations_client', integration: 'sendjim', link_url: '/integrations/sendjim/v3/integration')
      SystemSettings::Integration.create(company_name: 'ServiceMonster', short_description: 'Connect your ServiceMonster account and keep your customers engaged!', show_company_name: true, controller: 'integrations_client', integration: 'servicemonster', link_url: '/integrations/servicemonster')
      SystemSettings::Integration.create(company_name: 'ServiceTitan', short_description: 'Connect your ServiceTitan account and stay in touch with your Customers after the job!', show_company_name: true, controller: 'integrations_client', integration: 'servicetitan', link_url: '/integrations/servicetitan')
      SystemSettings::Integration.create(company_name: 'Slack', short_description: 'Build Slack into your Campaigns and receive immediate notifications!', show_company_name: false, controller: 'integrations_user', integration: 'slack', link_url: '/integrations/slack/integration')
      SystemSettings::Integration.create(company_name: 'Successware', short_description: 'Connect your Successware account and complete your business management software suite!', show_company_name: false, controller: 'integrations_client', integration: 'successware', link_url: '/integrations/successware')
      SystemSettings::Integration.create(company_name: 'SunbaseData', short_description: 'Connect your SunbaseData account and add your Customers directly into your calendar!', show_company_name: false, controller: 'integrations_client', integration: 'sunbasedata', link_url: 'integrations_sunbasedata_integration_path')
      SystemSettings::Integration.create(company_name: 'Webhooks & APIs', short_description: 'Send or receive data with other apps that support Webhooks!', show_company_name: true, controller: '', integration: '', link_url: '/integrations/webhook/integration')
      SystemSettings::Integration.create(company_name: 'Xencall', short_description: 'Connect your Xencall account and add your Customers to a call queue for automated calling!', show_company_name: true, controller: 'integrations_client', integration: 'xencall', link_url: '/integrations/xencall')
      SystemSettings::Integration.create(company_name: 'Zapier App', short_description: 'Try our App in Zapier. Create your own Zaps from almost any other app!', show_company_name: true, controller: 'integrations_user', integration: 'zapier', link_url: '/integrations/zapier/integrations')
      ActiveRecord::Base.record_timestamps = false
    end

    say_with_time 'Updating Client table...' do
      add_reference :clients, :affiliate, foreign_key: { to_table: :affiliates }, index: true

      Client.where.not(partner_id: nil).find_each do |client|
        client.update(affiliate_id: client.partner_id)
      end

      remove_reference :clients, :partner
    end

    say_with_time 'Updating Package table...' do
      add_reference :packages, :affiliate, foreign_key: { to_table: :affiliates }, index: true

      Package.where.not(partner_id: nil).find_each do |package|
        package.update(affiliate_id: package.partner_id)
      end

      remove_reference :packages, :partner
    end

    ActiveRecord::Base.record_timestamps = true
    say 'Turned on timestamps.'
  end

  def down
    ActiveRecord::Base.record_timestamps = false
    say 'Turned off timestamps.'

    say_with_time 'Removing Integrations table...' do
      drop_table :integrations
    end

    say_with_time 'Renaming Affiliates table to Partners...' do
  		rename_table   :affiliates, :partners
    end

    say_with_time 'Updating Client table...' do
      add_reference :clients, :partner, foreign_key: { to_table: :partners }, index: true

      Client.where.not(affiliate_id: nil).find_each do |client|
        client.update(partner_id: client.affiliate_id)
      end

      remove_reference :clients, :affiliate
    end

    say_with_time 'Updating Package table...' do
      add_reference :packages, :partner, foreign_key: { to_table: :partners }, index: true

      Package.where.not(affiliate_id: nil).find_each do |package|
        package.update(partner_id: package.affiliate_id)
      end

      remove_reference :packages, :affiliate
    end

    ActiveRecord::Base.record_timestamps = true
    say 'Turned on timestamps.'
  end
end
