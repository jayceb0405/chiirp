# frozen_string_literal: true

# app/presenters/clients/kpi_presenter.rb
module Clients
  # variables required by KPI views
  class KpiPresenter
    attr_accessor :kpi
    attr_reader   :client

    def initialize(args = {})
      self.client = args.dig(:client)
    end

    def client=(client)
      @client = if client.is_a?(Client)
                  client
                elsif client.is_a?(Integer)
                  Client.find_by(id: client)
                elsif self.user.is_a?(User)
                  self.user.client
                else
                  Client.new
                end
    end

    def kpis
      self.client.client_kpis.order(:name)
    end

    def options_for_kpi_criteria
      general_options = ['General Criteria', []]
      general_options[1]  << [' New Contacts', 'user_new_contacts', { data: { icon: 'fa fa-user' } }]
      general_options[1]  << [' Company New Contacts', 'client_new_contacts', { data: { icon: 'fa fa-building' } }]

      text_options = ['Text Buttons', []]
      text_options[1]     << ['Texts Sent', 'user_texts_sent', { data: { icon: 'fa fa-user' } }]
      text_options[1]     << ['Company Texts Sent', 'client_texts_sent', { data: { icon: 'fa fa-building' } }]
      text_options[1]     << ['Texts Received', 'user_texts_received', { data: { icon: 'fa fa-user' } }]
      text_options[1]     << ['Company Texts Received', 'client_texts_received', { data: { icon: 'fa fa-building' } }]

      email_options = ['Email Buttons', []]
      email_options[1]     << ['Emails Sent', 'user_emails_sent', { data: { icon: 'fa fa-user' } }]
      email_options[1]     << ['Company Emails Sent', 'client_emails_sent', { data: { icon: 'fa fa-building' } }]
      email_options[1]     << ['Emails Received', 'user_emails_received', { data: { icon: 'fa fa-user' } }]
      email_options[1]     << ['Company Emails Received', 'client_emails_received', { data: { icon: 'fa fa-building' } }]

      voice_options = ['Call Buttons', []]
      voice_options[1]     << ['Calls Placed', 'user_voice_sent', { data: { icon: 'fa fa-user' } }]
      voice_options[1]     << ['Company Calls Placed', 'client_voice_sent', { data: { icon: 'fa fa-building' } }]
      voice_options[1]     << ['Calls Received', 'user_voice_received', { data: { icon: 'fa fa-user' } }]
      voice_options[1]     << ['Company Calls Received', 'client_voice_received', { data: { icon: 'fa fa-building' } }]

      if @client.campaigns_count.positive?
        campaign_options = ['Campaign Buttons', []]
        campaign_options[1] << ['Completed Campaigns', 'user_campaigns_completed', { data: { icon: 'fa fa-user' } }]
        campaign_options[1] << ['Company Completed Campaigns', 'client_campaigns_completed', { data: { icon: 'fa fa-building' } }]
        campaign_options[1] += @client.campaigns.order(:name).map { |campaign| ["#{campaign.name} Completed", "user_campaign_#{campaign.id}", { data: { icon: 'fa fa-user' } }] }
        campaign_options[1] += @client.campaigns.order(:name).map { |campaign| ["Company #{campaign.name} Completed", "client_campaign_#{campaign.id}", { data: { icon: 'fa fa-building' } }] }
        campaign_options[1] += Campaign.keywords(@client.id).map { |campaign| ["#{campaign.name} Received", "user_keyword_#{campaign.id}", { data: { icon: 'fa fa-user' } }] }
        campaign_options[1] += Campaign.keywords(@client.id).map { |campaign| ["Company #{campaign.name} Received", "client_keyword_#{campaign.id}", { data: { icon: 'fa fa-building' } }] }
      else
        campaign_options     = []
      end

      if @client.groups_count.positive?
        group_options        = ['Group Buttons', []]
        group_options[1]    += @client.groups.order(:name).map { |group| [group.name.to_s, "user_group_#{group.id}", { data: { icon: 'fa fa-user' } }] }
        group_options[1]    += @client.groups.order(:name).map { |group| ["Company #{group.name}", "client_group_#{group.id}", { data: { icon: 'fa fa-building' } }] }
      else
        group_options        = []
      end

      tag_options          = ['Tag Buttons', []]
      tag_options[1]      += @client.tags.order(:name).map { |tag| [tag.name.to_s, "user_tag_#{tag.id}", { data: { icon: 'fa fa-user' } }] }
      tag_options[1]      += @client.tags.order(:name).map { |tag| ["Company #{tag.name}", "client_tag_#{tag.id}", { data: { icon: 'fa fa-building' } }] }

      if @client.trackable_links_count.positive?
        link_options         = ['Trackable Link Buttons', []]
        link_options[1]     += @client.trackable_links.order(:name).map { |trackable_link| [trackable_link.name.to_s, "user_trackable_link_#{trackable_link.id}", { data: { icon: 'fa fa-user' } }] }
        link_options[1]     += @client.trackable_links.order(:name).map { |trackable_link| ["Company #{trackable_link.name}", "client_trackable_link_#{trackable_link.id}", { data: { icon: 'fa fa-building' } }] }
      else
        link_options         = []
      end

      if @client.max_voice_recordings.positive?
        rvm_options          = ['Voice Recording Buttons', []]
        rvm_options[1]      += @client.voice_recordings.order(:recording_name).map { |voice_recording| [voice_recording.recording_name.to_s, "user_rvm_#{voice_recording.id}", { data: { icon: 'fa fa-user' } }] }
        rvm_options[1]      += @client.voice_recordings.order(:recording_name).map { |voice_recording| ["Company #{voice_recording.recording_name}", "client_rvm_#{voice_recording.id}", { data: { icon: 'fa fa-building' } }] }
      else
        rvm_options          = []
      end

      [general_options, text_options, email_options, voice_options] + (campaign_options.empty? ? [] : [campaign_options]) + (group_options.empty? ? [] : [group_options]) + [tag_options] + (link_options.empty? ? [] : [link_options]) + (rvm_options.empty? ? [] : [rvm_options])
    end

    def options_for_operator
      [['Division (÷)', '/'], ['Multiplication (x)', '*'], ['Addition (+)', '+'], ['Subtraction (-)', '-']]
    end
  end
end
