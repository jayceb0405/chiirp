# frozen_string_literal: true

# app/presenters/campaigns_presenter.rb
class CampaignsPresenter < BasePresenter
  attr_reader :campaign, :contact_campaign

  def initialize(args = {})
    super
    self.campaign         = args.dig(:campaign)
    self.contact_campaign = args.dig(:contact_campaign)
  end

  def campaign=(campaign)
    @campaign = case campaign
                when Campaign
                  campaign
                when Integer
                  Campaign.find_by(id: campaign)
                else

                  if @client.is_a?(Client)
                    self.client.campaigns.new
                  else
                    Campaign.new
                  end
                end
  end

  def contact_campaign_triggeractions
    @contact_campaign_triggeractions ||= self.contact_campaign.contact_campaign_triggeractions
                                             .select('contact_campaign_triggeractions.*, delayed_jobs.id AS dj_id, delayed_jobs.run_at AS dj_run_at')
                                             .left_joins(:delayed_jobs).uniq
  end

  def contact=(contact)
    super
    @contact_campaign_triggeractions = nil
    @contact_campaigns               = nil
    @contact_campaigns_future        = nil
    @contact_delayed_jobs            = nil
  end

  def contact_campaign=(contact_campaign)
    @contact_campaign = case contact_campaign
                        when Contacts::Campaign
                          contact_campaign
                        when Integer
                          Contacts::Campaign.find_by(id: contact_campaign)
                        else

                          if @contact.is_a?(Contact)
                            @contact.contact_campaigns.new
                          else
                            Contacts::Campaign.new
                          end
                        end
  end

  def contact_campaigns
    @contact_campaigns ||= @contact.contact_campaigns.order(created_at: :desc).includes(:campaign)
  end

  def contact_campaigns_future
    @contact_campaigns_future ||= @contact.delayed_jobs.where(process: 'start_campaign').order(run_at: :desc)
  end

  def contact_delayed_jobs
    @contact_delayed_jobs ||= @contact.delayed_jobs.group(:contact_campaign_id).pluck(:contact_campaign_id)
  end
end
