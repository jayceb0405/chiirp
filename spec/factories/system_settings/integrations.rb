# frozen_string_literal: true

FactoryBot.define do
  factory :integration, class: 'SystemSettings::Integration' do
    company_name { 'CallRail' }
    show_company_name { false }
    short_description { 'Handle incoming phone calls with ease!' }
    controller { 'integrations_user' }
    integration { 'callrail' }
    link_url { '/integrations/callrail/v3' }
  end
end
