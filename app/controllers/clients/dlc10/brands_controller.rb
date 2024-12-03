# frozen_string_literal: true

# app/controllers/clients/dlc10/brands_controller.rb
module Clients
  module Dlc10
    class BrandsController < Clients::Dlc10::BaseController
      before_action :create_dlc10_brand, only: %i[edit show]
      before_action :campaign, only: %i[edit show update]

      # (GET) edit 10DLC Brand data
      # /clients/dlc10/brands/:client_id/edit
      # edit_clients_dlc10_brand_path(:client_id)
      # edit_clients_dlc10_brand_url(:client_id)
      def edit
        cards = if params.permit(:brand).dig(:brand).to_bool
                  %(dlc10_brand_form)
                else
                  %(dlc10_brand_edit)
                end

        respond_to do |format|
          format.js { render partial: "clients/dlc10/#{dlc10_version}/js/show", locals: { cards: } }
          format.html { render 'clients/show', locals: { client_page_section: 'dlc10' } }
        end
      end

      # (GET) show 10DLC help info
      # /clients/dlc10/brands/:client_id
      # clients_dlc10_brand_path(:client_id)
      # clients_dlc10_brand_url(:client_id)
      def show
        render partial: "clients/dlc10/#{dlc10_version}/js/show", locals: { cards: %w[dlc10_brand_help] }
      end

      # (PUT/PATCH) update 10DLC Brand data
      # /clients/dlc10/brands/:client_id
      # clients_dlc10_brand_path(:client_id)
      # clients_dlc10_brand_url(:client_id)
      def update
        @client.dlc10_brand.update(params_brand)
        @campaign&.update(params_campaign) if params.include?(:clients_dlc10_campaign)

        unless params.permit(:commit).dig(:commit).to_s.casecmp?('Save Brand')
          charge_result = @client.dlc10_charged ? @client.charge_card(charge_amount: 5.00, setting_key: 'dlc10_brand_charge') : { success: true }

          if charge_result[:success]

            if params.permit(:commit).dig(:commit).to_s.casecmp?('submit_brand')
              errors = @client.dlc10_brand.register

              errors.each do |m|
                @client.dlc10_brand.errors.add(:base, m)
              end
            elsif params.permit(:commit).dig(:commit).to_s.casecmp?('resubmit_brand')
              errors = @client.dlc10_brand.update_registration

              errors.each do |m|
                @client.dlc10_brand.errors.add(:base, m)
              end
            end
          else
            @client.dlc10_brand.errors.add(:base, charge_result[:error_message])
          end
        end

        render partial: "clients/dlc10/#{dlc10_version}/js/show", locals: { cards: %w[dlc10_brand_edit] }
      end

      private

      def create_dlc10_brand
        return if @client.dlc10_brand

        @client.create_dlc10_brand(
          firstname:            current_user.firstname,
          lastname:             current_user.lastname,
          display_name:         @client.name,
          company_name:         @client.name,
          phone:                @client.phone,
          street:               [@client.address1, @client.address2].join(', ').chomp(', '),
          city:                 @client.city,
          state:                @client.state,
          zipcode:              @client.zip,
          email:                current_user.email,
          alt_business_id_type: 'NONE',
          brand_relationship:   (Time.current - @client.created_at).to_i > 90.days ? 'SMALL_ACCOUNT' : 'BASIC_ACCOUNT',
          ein_country:          'US',
          entity_type:          'PRIVATE_PROFIT',
          stock_exchange:       'NONE'
        )

        @client.dlc10_brand.campaigns.create(Clients::Dlc10::Campaign.default_options(@client.name))
      end

      def campaign
        @campaign = @client.dlc10_brand.campaigns.first if @client.dlc10_brand.verified_at.nil? && @client.dlc10_brand.campaigns.count == 1
      end

      def params_brand
        sanitized_params = params.require(:clients_dlc10_brand).permit(:firstname, :lastname, :company_name, :display_name, :street, :city, :state, :zipcode, :country, :phone, :email, :entity_type, :ein, :ein_country, :vertical, :alt_business_id_type, :alt_business_id, :stock_exchange, :stock_symbol, :website, :ip_address, :support_email)

        sanitized_params[:ein]     = sanitized_params[:ein].gsub(%r{\D}, '') if sanitized_params[:ein].present?
        sanitized_params[:website] = nil if sanitized_params[:website].blank?

        sanitized_params
      end

      def params_campaign
        params.require(:clients_dlc10_campaign).permit(:message_flow, :sample1, :sample2, :sample3, :sample4, :sample5)
      end
    end
  end
end
