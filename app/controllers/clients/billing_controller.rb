# frozen_string_literal: true

# app/controllers/clients/billing_controller.rb
module Clients
  # support for Client Billing endpoints
  class BillingController < Clients::ClientController
    before_action :authenticate_user!
    before_action :client
    before_action :authorize_user!

    # (GET)
    # /clients/billing/:id/edit
    # edit_clients_billing_path(:id)
    # edit_clients_billing_url(:id)
    def edit
      respond_to do |format|
        format.js { render partial: 'clients/js/show', locals: { cards: %w[billing] } }
        format.html { render 'clients/show', locals: { client_page_section: 'billing' } }
      end
    end

    # (PATCH)
    # /clients/billing/:id
    # clients_billing_path(:id)
    # clients_billing_url(:id)
    def update
      commit_button = params.dig(:commit).to_s.downcase
      add_credits   = params.dig(:add_credits).to_i

      if commit_button.casecmp?('charge my card')

        if add_credits.positive?
          # charge Client card for more credits
          result = @client.add_credits_by_charge({ credits_amt: add_credits, force: true })

          unless result[:success]
            # credits could NOT be added
            @client.errors.add(:client, result[:error_message])
          end
        end
      elsif commit_button.casecmp?('charge monthly fee')
        # charge Client monthly charge

        if @client.charge_monthly_fee
          @client.update(mo_charge_retry_count: 0)
        else
          @client.errors.add(:client, 'credit card charge failed.')
        end
      elsif commit_button.casecmp?('save account auto credit settings')
        @client.update(client_params)
      else
        # update Client
        @client.update(client_params)

        if @client.card_token.present?
          # received new card token

          if @client.client_token.present? && (customer = Creditcard::Customer.find_by(client_id: @client.client_token))
            # update Client token from new card token
            customer.update(
              card_id:          @client.card_token,
              client_id:        @client.client_token,
              cust_description: "#{@client.name} (#{@client.phone})",
              email:            @client.def_user&.email,
              name:             @client.name
            )
          else
            # create a Client token from new card token
            customer = Creditcard::Customer.create(
              card_id:          @client.card_token,
              cust_description: "#{@client.name} (#{@client.phone})",
              email:            @client.def_user&.email,
              name:             @client.name
            )
          end

          if customer.valid?
            # credit card customer id was updated
            @client.update(card_token: customer.card_id.to_s, client_token: customer.client_id.to_s)

            # get the current card info
            if (card = Creditcard::Card.find_by(card_id: @client.card_token, client_id: @client.client_token))
              # credit card info was retrieved
              @client.update(card_brand: card.card_brand.to_s, card_last4: card.card_last4.to_s, card_exp_month: card.card_exp_month.to_s, card_exp_year: card.card_exp_year.to_s)
            else
              # credit card info was NOT retrieved
              @client.errors.add(:client, 'Credit card was not found')
            end
          else
            # credit card customer id was NOT updated
            customer.errors.each do |e|
              @client.errors.add(e.attribute, e.message)
            end
          end
        end
      end

      sweetalert_error('Oops...', '', @client.errors.full_messages.join('<br />'), { persistent: 'OK' }) if @client.errors.any?

      respond_to do |format|
        format.js { render partial: 'clients/js/show', locals: { cards: %w[billing credit_balance] } }
        format.html { redirect_to edit_clients_billing_path(@client.id) }
      end
    end

    private

    def authorize_user!
      super

      return if current_user.access_controller?('clients', 'billing', session)

      raise ExceptionHandlers::UserNotAuthorized.new('My Company Profile > Billing', root_path)
    end

    def client_params
      response = params.require(:client).permit(:auto_min_amount, :auto_add_amount, :card_token)

      response[:auto_min_amount]           = response[:auto_min_amount].to_i if response.include?(:auto_min_amount)
      response[:credit_charge_retry_level] = response[:auto_min_amount].to_i if response.include?(:auto_min_amount)
      response[:auto_add_amount]           = response[:auto_add_amount].to_i if response.include?(:auto_add_amount)

      response
    end
  end
end
