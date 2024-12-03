# frozen_string_literal: true

# app/jobs/contacts/campaigns/stop_job.rb
module Contacts
  module Campaigns
    class StopJob < ApplicationJob
      # start a Campaign on a Contact
      # Contacts::Campaigns::StopJob.perform_now()
      # Contacts::Campaigns::StopJob.set(wait_until: 1.day.from_now).perform_later()
      # Contacts::Campaigns::StopJob.set(wait_until: 1.day.from_now, priority: 0).perform_later()

      def initialize(**args)
        super

        @process = (args.dig(:process).presence || 'stop_campaign').to_s
      end

      # perform the ActiveJob
      #   (req) contact_id:                     (Integer)
      #
      #   (opt) campaign_id:                    (Integer)
      #   (opt) contact_campaign_id:            (Integer)
      #   (opt) keep_triggeraction_ids          (Array)
      #   (opt) limit_to_estimate_job_visit_id: (Boolean)
      #   (opt) multi_stop:                     (String)
      #   (opt) triggeraction_id:               (Integer)
      def perform(**args)
        super

        return nil unless args.dig(:contact_id).to_i.positive? && (contact = Contact.find_by(id: args[:contact_id].to_i)).present? && contact.client.active?

        contact_campaign = (args.dig(:contact_campaign_id).to_i.positive? && contact.contact_campaigns.find_by(id: args.dig(:contact_campaign_id).to_i)) || nil

        case args.dig(:campaign_id).to_s[0, 6]
        when 'all'
          contact_campaigns = Contacts::Campaign.where(contact_id: contact.id)
          delayed_jobs      = {}
        when 'this'
          contact_campaigns = Contacts::Campaign.where(id: [contact_campaign&.id])
          delayed_jobs      = {}
        when 'all_ot'
          stop_ids = contact_campaign_ids_to_stop(contact, contact.active_contact_campaign_ids, contact_campaign, args.dig(:limit_to_estimate_job_visit_id))
          stop_ids.delete(contact_campaign&.id)
          contact_campaigns, delayed_jobs = stop_contact_campaigns_all_other(contact, stop_ids, (args.dig(:multi_stop) || 'all'), contact_campaign)
        when 'group_'
          contact_campaign_ids            = contact.active_contact_campaign_ids & contact.contact_campaigns.where(campaign_id: contact.client.campaigns.where(campaign_group_id: args.dig(:campaign_id).to_s.split('_').last.to_i)).pluck(:id)
          stop_ids                        = contact_campaign_ids_to_stop(contact, contact_campaign_ids, contact_campaign, args.dig(:limit_to_estimate_job_visit_id))
          contact_campaigns, delayed_jobs = stop_contact_campaigns_group(contact, stop_ids, args.dig(:multi_stop), contact_campaign)
        else
          contact_campaign_ids            = contact.active_contact_campaign_ids & contact.contact_campaigns.where(campaign_id: args.dig(:campaign_id).to_i).pluck(:id)
          stop_ids                        = contact_campaign_ids_to_stop(contact, contact_campaign_ids, contact_campaign, args.dig(:limit_to_estimate_job_visit_id))
          contact_campaigns, delayed_jobs = stop_contact_campaigns_everything_else(contact:, active_contact_campaign_ids: stop_ids, multi_stop: args.dig(:multi_stop), campaign_id: args.dig(:campaign_id), contact_campaign:)
        end

        JsonLog.info 'Contact.stop_contact_campaigns', { contact_campaigns:, delayed_jobs: }

        contact_campaigns.each { |cc| cc.stop(keep_triggeraction_ids: [args.dig(:keep_triggeraction_ids) || []].flatten) }

        delayed_jobs.each do |delayed_job|
          delayed_job.destroy if delayed_job.locked_at.nil?
        end
      end

      private

      # return the Contacts::Campaign ids that will be stopped
      # only stop Campaigns related to contact_job_id, contact_invoice_id, contact_estimate_id, contact_subscription_id or contact_visit_id when limit_to_estimate_job_visit_id = true
      # contact_campaign_ids_to_stop()
      #   (req) active_contact_campaign_ids:    (Array)
      #   (req) contact:                        (Contact)
      #   (req) contact_campaign:               (Contacts::Campaign)
      #   (req) limit_to_estimate_job_visit_id: (Boolean)
      def contact_campaign_ids_to_stop(contact, active_contact_campaign_ids, contact_campaign, limit_to_estimate_job_visit_id)
        return active_contact_campaign_ids unless limit_to_estimate_job_visit_id.to_bool && active_contact_campaign_ids.present?

        if contact_campaign&.data&.dig(:contact_estimate_id).present?

          if (contact_estimate = contact.estimates.find_by(id: contact_campaign.data[:contact_estimate_id])) && contact_estimate.ext_source == 'servicemonster' && (contact_job = contact.jobs.find_by(ext_id: contact_estimate.ext_id))
            Contacts::Campaign.where(id: active_contact_campaign_ids).map { |cc| cc.id if cc.data.dig(:contact_estimate_id).to_i == contact_campaign.data[:contact_estimate_id].to_i || cc.data.dig(:contact_job_id).to_i == contact_job.id }.compact_blank
          else
            Contacts::Campaign.where(id: active_contact_campaign_ids).map { |cc| cc.id if cc.data.dig(:contact_estimate_id).to_i == contact_campaign.data[:contact_estimate_id].to_i }.compact_blank
          end
        elsif contact_campaign&.data&.dig(:contact_invoice_id).present?

          if (contact_invoice = contact.invoices.find_by(id: contact_campaign.data[:contact_invoice_id])) && contact_invoice.ext_source == 'servicemonster' && (contact_job = contact.jobs.find_by(ext_id: contact_invoice.ext_id))
            Contacts::Campaign.where(id: active_contact_campaign_ids).map { |cc| cc.id if cc.data.dig(:contact_invoice_id).to_i == contact_campaign.data[:contact_invoice_id].to_i || cc.data.dig(:contact_job_id).to_i == contact_job.id }.compact_blank
          else
            Contacts::Campaign.where(id: active_contact_campaign_ids).map { |cc| cc.id if cc.data.dig(:contact_invoice_id).to_i == contact_campaign.data[:contact_invoice_id].to_i }.compact_blank
          end
        elsif contact_campaign&.data&.dig(:contact_job_id).present?

          if (contact_job = contact.jobs.find_by(id: contact_campaign.data[:contact_job_id])) && contact_job.ext_source == 'servicemonster' && (contact_estimate = contact.estimates.find_by(ext_id: contact_job.ext_id))
            Contacts::Campaign.where(id: active_contact_campaign_ids).map { |cc| cc.id if cc.data.dig(:contact_job_id).to_i == contact_campaign.data[:contact_job_id].to_i || cc.data.dig(:contact_estimate_id).to_i == contact_estimate.id }.compact_blank
          else
            Contacts::Campaign.where(id: active_contact_campaign_ids).map { |cc| cc.id if cc.data.dig(:contact_job_id).to_i == contact_campaign.data[:contact_job_id].to_i }.compact_blank
          end
        elsif contact_campaign&.data&.dig(:contact_subscription_id).present?
          Contacts::Campaign.where(id: active_contact_campaign_ids).map { |cc| cc.id if cc.data.dig(:contact_subscription_id).to_i == contact_campaign.data[:contact_subscription_id].to_i }.compact_blank
        elsif contact_campaign&.data&.dig(:contact_visit_id).present?
          Contacts::Campaign.where(id: active_contact_campaign_ids).map { |cc| cc.id if cc.data.dig(:contact_visit_id).to_i == contact_campaign.data[:contact_visit_id].to_i }.compact_blank
        else
          active_contact_campaign_ids
        end
      end

      # return Contacts::Campaigns & DelayedJobs to destroy
      # stop_contact_campaigns_all_other()
      #   (req) active_contact_campaign_ids: (Array)
      #   (req) contact:                     (Contact)
      #   (req) contact_campaign:            (Contacts::Campaign)
      #   (req) multi_stop:                  (String)
      def stop_contact_campaigns_all_other(contact, active_contact_campaign_ids, multi_stop, contact_campaign)
        case (multi_stop.presence || 'all').to_s.downcase
        when 'first'
          contact_campaigns = Contacts::Campaign.where(id: active_contact_campaign_ids).order(created_at: :asc).limit(1)
          delayed_jobs      = contact_campaigns.present? ? {} : contact.delayed_jobs.where(process: 'start_campaign').where.not(contact_campaign_id: contact_campaign&.id).order(created_at: :asc).limit(1)
        when 'last'
          delayed_jobs      = contact.delayed_jobs.where(process: 'start_campaign').where.not(contact_campaign_id: contact_campaign&.id).order(created_at: :desc).limit(1)
          contact_campaigns = if delayed_jobs.present?
                                {}
                              elsif Contacts::Campaign.where(id: active_contact_campaign_ids).length > 1
                                Contacts::Campaign.where(id: active_contact_campaign_ids).order(created_at: :desc).limit(1)
                              else
                                active_contact_campaign_ids.delete(contact_campaign&.id)
                                Contacts::Campaign.where(id: active_contact_campaign_ids).order(created_at: :desc).limit(1)
                              end
        else
          contact_campaigns = Contacts::Campaign.where(id: active_contact_campaign_ids)
          delayed_jobs      = contact.delayed_jobs.where(process: 'start_campaign').where.not(contact_campaign_id: contact_campaign&.id)
        end

        [contact_campaigns, delayed_jobs]
      end

      # return Contacts::Campaigns & DelayedJobs to destroy
      # stop_contact_campaigns_everything_else()
      #   (req) active_contact_campaign_ids: (Array)
      #   (req) campaign_id:                 (Integer)
      #   (req) contact:                     (Contact)
      #
      #   (opt) contact_campaign:            (Contacts::Campaign / req only when multi_stop = 'first' or 'last')
      #   (opt) multi_stop:                  (String / default: 'all')
      def stop_contact_campaigns_everything_else(contact:, active_contact_campaign_ids:, campaign_id:, contact_campaign:, multi_stop: 'all')
        return unless contact.is_a?(Contact)

        active_contact_campaign_ids = active_contact_campaign_ids.map(&:to_i)
        campaign_id                 = campaign_id.to_i

        case multi_stop.to_s.downcase
        when 'first'
          active_contact_campaign_ids.delete(contact_campaign&.id)
          contact_campaigns = Contacts::Campaign.where(id: active_contact_campaign_ids).order(created_at: :asc).limit(1)
          delayed_jobs      = contact_campaigns.present? ? {} : contact.delayed_jobs.where(process: 'start_campaign').where('data @> ?', { campaign_id: }.to_json).order(created_at: :asc).limit(1)
        when 'last'
          delayed_jobs      = contact.delayed_jobs.where(process: 'start_campaign').where('data @> ?', { campaign_id: }.to_json).order(created_at: :desc).limit(1)
          contact_campaigns = if delayed_jobs.present?
                                {}
                              elsif Contacts::Campaign.where(id: active_contact_campaign_ids).length > 1
                                Contacts::Campaign.where(id: active_contact_campaign_ids).order(created_at: :desc).limit(1)
                              else
                                active_contact_campaign_ids.delete(contact_campaign&.id)
                                Contacts::Campaign.where(id: active_contact_campaign_ids).order(created_at: :desc).limit(1)
                              end
        else
          # active_contact_campaign_ids.delete(contact_campaign&.id)
          contact_campaigns = Contacts::Campaign.where(id: active_contact_campaign_ids)
          delayed_jobs      = contact.delayed_jobs.where(process: 'start_campaign').where('data @> ?', { campaign_id: }.to_json)
        end

        [contact_campaigns, delayed_jobs]
      end

      # return Contacts::Campaigns & DelayedJobs to destroy
      # stop_contact_campaigns_group()
      #   (req) active_contact_campaign_ids: (Array)
      #   (req) contact:                     (Contact)
      #   (req) contact_campaign:            (Contacts::Campaign)multi_stop
      #   (req) multi_stop:                  (String)
      def stop_contact_campaigns_group(contact, active_contact_campaign_ids, multi_stop, contact_campaign)
        case (multi_stop || 'all').to_s.downcase
        when 'first'
          active_contact_campaign_ids.delete(contact_campaign&.id)
          contact_campaigns = Contacts::Campaign.where(id: active_contact_campaign_ids).order(created_at: :asc).limit(1)
          delayed_jobs      = contact_campaigns.present? ? {} : contact.delayed_jobs.where(process: 'start_campaign').where.not(contact_campaign_id: contact_campaign&.id).order(created_at: :asc).limit(1)
        when 'last'
          delayed_jobs      = contact.delayed_jobs.where(process: 'start_campaign').where.not(contact_campaign_id: contact_campaign&.id).order(created_at: :desc).limit(1)
          contact_campaigns = if delayed_jobs.present?
                                {}
                              elsif Contacts::Campaign.where(id: active_contact_campaign_ids).length > 1
                                Contacts::Campaign.where(id: active_contact_campaign_ids).order(created_at: :desc).limit(1)
                              else
                                active_contact_campaign_ids.delete(contact_campaign&.id)
                                Contacts::Campaign.where(id: active_contact_campaign_ids).order(created_at: :desc).limit(1)
                              end
        else
          active_contact_campaign_ids.delete(contact_campaign&.id)
          contact_campaigns = Contacts::Campaign.where(id: active_contact_campaign_ids)
          delayed_jobs      = contact.delayed_jobs.where(process: 'start_campaign').where.not(contact_campaign_id: contact_campaign&.id)
        end

        [contact_campaigns, delayed_jobs]
      end
    end
  end
end
