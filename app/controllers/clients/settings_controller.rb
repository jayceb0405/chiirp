# frozen_string_literal: true

# app/controllers/clients/settings_controller.rb
module Clients
  # support for editing Client settings
  class SettingsController < Clients::ClientController
    before_action :authenticate_user!
    before_action :client
    before_action :authorize_user!

    # (GET)
    # /clients/settings/:id/edit
    # edit_clients_setting_path(:id)
    # edit_clients_setting_url(:id)
    def edit
      respond_to do |format|
        format.js { render partial: 'clients/js/show', locals: { cards: %w[settings] } }
        format.html { render 'clients/show', locals: { client_page_section: 'settings' } }
      end
    end

    # (PATCH)
    # /clients/settings/:id
    # clients_setting_path(:id)
    # clients_setting_url(:id)
    def update
      client_was_active = @client.active?

      if ['save settings', 'save package settings'].include?(params.dig(:commit).to_s.downcase)
        # update Client
        @client.update(client_params)
      end

      # if Client is not an Agency / remove all Agency connections if they exist
      unless @client.agency_access

        Client.where('data @> ?', { my_agencies: [@client.id] }.to_json).find_each do |client|
          client.my_agencies.delete(@client.id)
          client.save
        end
      end

      # if Client active status was changed from true to false
      if client_was_active && !@client.active?
        @client.deactivate(user: current_user)

        Rails.logger.info "Clients::SettingsController.update (Client Deactivated): #{{ client_id: @client.id, client_name: @client.name, user_id: current_user.id }.inspect} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"

        # Client is NOT active and was referred by an affiliate
        FirstPromoter.new.register_cancellation(client_id: @client.id) if @client.fp_affiliate.present?
      end

      if params.dig(:commit).to_s.casecmp?('charge credit card') && params.dig(:charge_card).to_d.positive?
        # charge Client card for more credits
        result = @client.charge_card(
          charge_amount: params[:charge_card].to_d,
          setting_key:   'added_charge'
        )

        unless result[:success]
          # charge did not complete successfully
          @client.errors.add(:client, result[:error_message])
        end
      end

      respond_to do |format|
        format.js { render partial: 'clients/js/show', locals: { cards: %w[settings] } }
        format.html { redirect_to root_path }
      end
    end

    private

    def authorize_user!
      super
      return if current_user.access_controller?('clients', 'settings', session)

      raise ExceptionHandlers::UserNotAuthorized.new('My Company Profile > Settings', root_path)
    end

    def client_params
      response = params.require(:client).permit(
        :active, :agency_access, :contact_matching_ignore_emails, :contact_matching_with_email, :credit_charge, :current_balance, :def_user_id, :dlc10_required, :dlc10_charged,
        :first_payment_delay_days, :first_payment_delay_months,
        :max_phone_numbers, :mo_charge, :mo_charge_retry_count, :mo_credits, :next_pmt_date, :onboarding_scheduled,
        :affiliate_id, :package_id, :package_page_id, :phone_vendor, :primary_area_code, :promo_credit_charge, :promo_max_phone_numbers, :promo_mo_charge, :promo_mo_credits, :promo_months,
        :searchlight_fee, :setup_fee, :terms_accepted, :text_delay, :time_zone, :trial_credits, :unlimited
      )

      response[:active]                         = response.dig(:active).to_bool if response.include?(:active)
      response[:agency_access]                  = response.dig(:agency_access).to_bool if response.include?(:agency_access)
      response[:contact_matching_ignore_emails] = response.dig(:contact_matching_ignore_emails).split(',').map(&:strip).compact_blank if response.include?(:contact_matching_ignore_emails)
      response[:contact_matching_with_email]    = response.dig(:contact_matching_with_email).to_bool if response.include?(:contact_matching_with_email)
      response[:credit_charge]                  = response.dig(:credit_charge).to_d if response.include?(:credit_charge)
      response[:current_balance]                = (response.dig(:current_balance).to_d * BigDecimal(100)).to_i if response.include?(:current_balance)
      response[:dlc10_required] = response.dig(:dlc10_required).to_bool if response.include?(:dlc10_required)
      response[:dlc10_charged]                  = response.dig(:dlc10_charged).to_bool if response.include?(:dlc10_charged)
      response[:first_payment_delay_days]       = response.dig(:first_payment_delay_days).to_i if response.include?(:first_payment_delay_days)
      response[:first_payment_delay_months]     = response.dig(:first_payment_delay_months).to_i if response.include?(:first_payment_delay_months)
      response[:max_phone_numbers]              = response[:max_phone_numbers].to_i if response.include?(:max_phone_numbers)
      response[:mo_charge]                      = response.dig(:mo_charge).to_d if response.include?(:mo_charge)
      response[:mo_charge_retry_count]          = response.dig(:mo_charge_retry_count).to_i if response.include?(:mo_charge_retry_count)
      response[:mo_credits]                     = response.dig(:mo_credits).to_d if response.include?(:mo_credits)
      response[:next_pmt_date]                  = response.dig(:next_pmt_date).to_s if response.include?(:next_pmt_date)
      response[:onboarding_scheduled]           = response.dig(:onboarding_scheduled).to_s if response.include?(:onboarding_scheduled)
      response[:package_id]                     = response.dig(:package_id).to_i if response[:package_id].present?
      response[:package_page_id]                = response.dig(:package_page_id).to_i if response[:package_page_id].present?
      response[:affiliate_id]                   = response.dig(:affiliate_id).to_i.positive? ? response[:affiliate_id].to_i : nil
      response[:phone_vendor]                   = response.dig(:phone_vendor).to_s if response.include?(:phone_vendor)
      response[:promo_credit_charge]            = response.dig(:promo_credit_charge).to_d if response.include?(:promo_credit_charge)
      response[:promo_max_phone_numbers]        = response.dig(:promo_max_phone_numbers).to_i if response.include?(:promo_max_phone_numbers)
      response[:promo_mo_charge]                = response.dig(:promo_mo_charge).to_d if response.include?(:promo_mo_charge)
      response[:promo_mo_credits]               = response.dig(:promo_mo_credits).to_d if response.include?(:promo_mo_credits)
      response[:promo_months]                   = response.dig(:promo_months).to_i if response.include?(:promo_months)
      response[:searchlight_fee]                = response[:searchlight_fee].to_d if response.include?(:searchlight_fee)
      response[:setup_fee]                      = response.dig(:setup_fee).to_d if response.include?(:setup_fee)
      response[:terms_accepted]                 = response.dig(:terms_accepted).to_s if response.include?(:terms_accepted)
      response[:text_delay]                     = response.dig(:text_delay).to_i if response.include?(:text_delay)
      response[:trial_credits]                  = response.dig(:trial_credits).to_d if response.include?(:trial_credits)
      response[:unlimited]                      = response.dig(:unlimited).to_bool if response.include?(:unlimited)

      response[:onboarding_scheduled]           = Time.use_zone(@client.time_zone) { Chronic.parse(response[:onboarding_scheduled]) }.utc.iso8601 if response.dig(:onboarding_scheduled).to_s.present?
      response[:terms_accepted]                 = Time.use_zone(@client.time_zone) { Chronic.parse(response[:terms_accepted]) }.utc.iso8601 if response.dig(:terms_accepted).to_s.present?
      response[:next_pmt_date]                  = Time.use_zone(@client.time_zone) { Chronic.parse(response[:next_pmt_date]) }.utc.to_date if response.dig(:next_pmt_date).to_s.present?

      response
    end
  end
end
