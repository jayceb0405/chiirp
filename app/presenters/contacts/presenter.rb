# frozen_string_literal: true

# app/presenters/contacts/presenter.rb
module Contacts
  class Presenter < BasePresenter
    attr_reader :contact, :client, :delayed_job, :user

    # Contacts::Presenter.new()
    def initialize(args = {})
      super

      @contact_phones              = nil
      @delayed_job                 = nil
      @delayed_job_action_name     = nil
      @delayed_job_icon            = nil
      @delayed_job_object_args     = nil
      @folders                     = nil
      @label_options               = nil
      @lead_sources_array          = nil
      @scheduled_actions           = nil
      @google_calendar_array       = nil
      @user_api_integration_google = nil
    end

    def american_birthdate
      @contact.birthdate.nil? ? '' : @contact.birthdate.strftime('%m/%d/%Y')
    end

    def contact_birthdate_formatted
      @contact.birthdate.present? ? @contact.birthdate.in_time_zone(@client.time_zone).strftime('%m/%d/%Y') : ''
    end

    def contact_campaigns
      @contact_campaigns ||= @contact.client.campaign_groups.order(:name)
    end

    def contact_phone_labels_for_select
      @contact.contact_phones.select(:label).map { |p| [p.label.titleize, p.label] }
    end

    def contact_phones
      @contact_phones || @contact.contact_phones
    end

    def delayed_job=(delayed_job)
      @delayed_job_action_name = nil
      @delayed_job_icon        = nil
      @delayed_job_object_args = nil

      @delayed_job = case delayed_job
                     when DelayedJob, Delayed::Backend::ActiveRecord::Job
                       delayed_job
                     when Integer
                       Delayed::Job.find_by(id: delayed_job)
                     else
                       Delayed::Job.new
                     end
    end

    def delayed_job_action_name
      @delayed_job_action_name ||= case @delayed_job.process.downcase
                                   when 'send_email'
                                     EmailTemplate.find_by(id: @delayed_job.data.dig('email_template_id'))&.name.presence || 'Empty Template'
                                   when 'send_rvm'
                                     @delayed_job.data.dig('message').to_s
                                   when 'send_text'
                                     "#{ApplicationController.helpers.truncate(@delayed_job.data['content'], length: 80)}#{@delayed_job.data.dig('image_id_array').is_a?(Array) && @delayed_job.data['image_id_array'].present? ? "<small class=\"ml-2\">(#{I18n.t(:image, count: @delayed_job.data['image_id_array'].length)})</small>" : ''}"
                                   when 'start_campaign'
                                     "Start #{::Campaign.find_by(id: @delayed_job.data.dig('campaign_id'))&.name.presence || 'Undefined'}"
                                   when 'stop_campaign'
                                     "Stop #{::Campaign.find_by(id: @delayed_job.data.dig('campaign_id'))&.name.presence || 'Undefined'}"
                                   else
                                     'Unknown Action'
                                   end
    end

    def delayed_job_campaign_name
      @delayed_job.triggeraction&.trigger&.campaign&.name.to_s
    end

    def delayed_job_icon
      @delayed_job_icon ||= case @delayed_job.process.downcase
                            when 'send_email'
                              '<i class="fa fa-envelope mr-2"></i>'
                            when 'send_rvm'
                              '<i class="fa fa-voicemail mr-2"></i>'
                            when 'send_text'
                              '<i class="fa fa-comments mr-2"></i>'
                            when 'start_campaign', 'stop_campaign'
                              '<i class="fa fa-filter mr-2"></i>'
                            else
                              '<i class="fa fa-question mr-2"></i>'
                            end
    end

    def delayed_job_object_args
      @delayed_job_object_args ||= @delayed_job.payload_object.args.first
    end

    def ext_references_target_array
      ApplicationController.helpers.ext_references_options(self.client)
    end

    def folders
      @folders ||= Folder.where(client_id: @client.id, active: true).order(name: :asc)
    end

    def google_calendar_array
      return [] unless @client.integrations_allowed.include?('google')

      @google_calendar_array ||= @user.google_calendar_array(self.user_api_integration_google)
    end

    def group_options
      @client.groups.pluck(:id, :name).map { |user| [user[1], user[0]] }
    end

    def label_options
      @label_options ||= @client.contact_phone_labels_for_select
    end

    def lead_sources_array
      @lead_sources_array ||= @client.lead_sources.pluck(:name, :id)
    end

    def scheduled_actions
      @scheduled_actions || @contact.scheduled_actions.includes(:triggeraction, triggeraction: { trigger: :campaign })
    end

    def scheduled_actions?
      self.scheduled_actions.any?
    end

    def stage_options
      StageParent.for_grouped_select(client_id: @client.id)
    end

    def user=(user)
      @user = if user.is_a?(User)
                user
              elsif user.is_a?(Integer)
                User.find_by(id: user)
              elsif @contact.is_a?(Contact)
                @contact.user
              elsif @client.is_a?(Client)
                @client.users.new
              else
                User.new
              end
    end

    def user_api_integration_google
      @user_api_integration_google ||= @user.user_api_integrations.find_or_create_by(target: 'google', name: '')
    end

    def user_options
      @client.users.where.not(id: nil).order(:lastname, :firstname).pluck(:id, :firstname, :lastname).map { |user| [Friendly.new.fullname(user[1], user[2]), user[0]] }
    end
  end
end
