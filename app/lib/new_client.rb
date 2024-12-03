# frozen_string_literal: true

# app/lib/new_client.rb
module NewClient
  # buy a new Client's first phone number
  # NewClient.buy_phone_number(client: Client)
  #   (req) client: (Client)
  def self.buy_phone_number(args = {})
    client   = args.dig(:client)
    response = { success: false, phone_number: nil, error_message: '' }

    return response unless client.is_a?(Client)

    if (available_phone_numbers = PhoneNumbers::Router.find(phone_vendor: client.phone_vendor, area_code: client.phone[0, 3], local: true)).present? &&
       (new_phone_number = PhoneNumbers::Router.buy(phone_vendor: client.phone_vendor, tenant: client.tenant, client_id: client.id, client_name: client.name, phone_number: available_phone_numbers.first[:phone_number]))[:success] &&
       (twnumber = client.twnumbers.create(
         phonenumber:     new_phone_number[:phone_number],
         name:            ActionController::Base.helpers.number_to_phone(new_phone_number[:phone_number].clean_phone(client.primary_area_code)),
         vendor_id:       new_phone_number[:phone_number_id],
         phone_vendor:    new_phone_number[:phone_vendor],
         vendor_order_id: new_phone_number[:vendor_order_id]
       ))
      response[:success] = true
      response[:phone_number] = twnumber[:phonenumber]

      twnumber.phone_number_status_update
    else
      error_messages = []
      error_messages << "Available phone numbers not found for area code (#{client.phone[0, 3]})." if defined?(available_phone_numbers) && available_phone_numbers.blank?
      error_messages << "Phone Number (#{new_phone_number[:phone_number]}) purchase failed." if defined?(new_phone_number) && !new_phone_number.nil? && !new_phone_number[:success]
      error_messages << twnumber.errors.full_messages if defined?(twnumber) && twnumber&.errors.present?
      response[:error_message] = error_messages.join(', ')
      Rails.logger.info "NewClient.buy_phone_number: #{{ errors: response[:error_message] }.inspect} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"
    end

    response
  end

  # Example:
  #   response = NewClient.create(
  #     client: Hash,
  #     user: Hash
  #     package_id: Integer,
  #     package_page_id: Integer,
  #     create_cc_customer: Boolean,
  #     credit_card: Boolean,
  #     charge_client: Boolean,
  #     send_invite: Boolean
  #   )
  #
  #   (req) client:               (Hash)
  #   (req) user:                 (Hash)
  #   (req) package_id:           (Integer)
  #   (req) package_page_id:      (Integer)
  #
  #   (opt) create_cc_customer:   (Boolean)
  #   (opt) credit_card:          (Boolean)
  #   (opt) charge_client:        (Boolean)
  #   (opt) dlc10_brand:          (Hash)
  #   (opt) send_invite:          (Boolean)
  #
  def self.create(args)
    client               = args.dig(:client).is_a?(Hash) ? args[:client] : {}
    dlc10_brand          = args.dig(:dlc10_brand).is_a?(Hash) ? args[:dlc10_brand] : {}
    user                 = args.dig(:user).is_a?(Hash) ? args[:user] : {}
    package_id           = args.dig(:package_id).to_i
    package_page_id      = args.dig(:package_page_id).to_i
    create_cc_customer   = args.dig(:create_cc_customer).to_bool
    credit_card          = args.dig(:credit_card).to_bool
    charge_client        = args.dig(:charge_client).to_bool
    send_invite          = args.dig(:send_invite).to_bool
    response             = { success: false, client: nil, error_message: '' }

    client[:name]            ||= ''
    client[:address1]        ||= ''
    client[:address2]        ||= ''
    client[:city]            ||= ''
    client[:state]           ||= ''
    client[:zip]             ||= ''
    client[:phone]           ||= ''
    client[:time_zone]       ||= ''
    client[:def_user_id]     ||= 0
    client[:current_balance] ||= 0
    client[:next_pmt_date]   ||= Time.current
    client[:contact_id]      ||= 0
    client[:tenant]          ||= ''
    client[:card_token]      ||= ''

    user[:firstname]         ||= ''
    user[:lastname]          ||= ''
    user[:phone]             ||= ''
    user[:email]             ||= ''

    begin
      ActiveRecord::Base.transaction do
        # initialize new Client
        response[:client] = Client.create(client)

        Rails.logger.info "NewClient.create: #{{ errors: response[:client].errors.full_messages }.inspect} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }" if response[:client].errors.present?

        # create customer at credit card processor
        result = create_cc_customer ? response[:client].create_credit_card_customer : { success: true }

        if result[:success]
          # get credit card info from processor
          result = credit_card ? response[:client].update_credit_card : { success: true }

          if result[:success]

            if package_id.positive? && (package = Package.find_by(tenant: response[:client].tenant, id: package_id))
              # Package was found

              if package_page_id.positive? && (package_page = PackagePage.find_by(tenant: response[:client].tenant, id: package_page_id))
                # PackagePage was found

                # update Client with Package settings
                response[:client].update_package_settings(package_page:, package:)

                # create new User
                result = NewClient.create_user(client: response[:client], user:)

                if result[:success]
                  # set Client to correct default User
                  response[:client].update(def_user_id: result[:user].id)

                  NewClient.create_support_contact(client: response[:client])

                  NewClient.buy_phone_number(client: response[:client])

                  if credit_card
                    if (customer = Creditcard::Customer.find_by(client_id: response[:client].client_token))
                      # update Client token from new card token
                      customer.update(card_id: response[:client].card_token, name: response[:client].name, email: response[:client].def_user&.email)
                    else
                      response = { success: false, client: nil, error_message: 'Client credit card data was not found.' }
                      Rails.logger.info "NewClient.create: #{{ response: }.inspect} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"
                      raise ActiveRecord::Rollback, "ActiveRecord::Rollback: #{response[:error_message]}"
                    end
                  end

                  NewClient.import_campaigns(client: response[:client], package:)

                  NewClient.corporate_contact(client: response[:client], package:)

                  if dlc10_brand.any? && package.dlc10_required
                    # charge for DLC10 Brand
                    dlc10_charge_result = if credit_card
                                            response[:client].dlc10_charged ? response[:client].charge_card(charge_amount: 5.00, setting_key: 'dlc10_brand_charge') : { success: true }
                                          else
                                            { success: true }
                                          end

                    # create new DLC10 Brand
                    NewClient.create_dlc10_brand(client: response[:client], dlc10_brand:) if dlc10_charge_result[:success]
                  end

                  NewClient.send_invite(client: response[:client], user: result[:user]) if send_invite

                  response[:success] = true
                else
                  response = { success: false, client: nil, error_message: result[:error_message] }
                  Rails.logger.info "NewClient.create: #{{ response: }.inspect} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"
                  raise ActiveRecord::Rollback, "ActiveRecord::Rollback: #{response[:error_message]}"
                end

                if charge_client
                  # charge credit card
                  result = response[:client].charge_for_startup

                  if result[:success]
                    # startup charges were successful

                    # add credits to Client account
                    if (response[:client].first_payment_delay_days + response[:client].first_payment_delay_months).zero?
                      # monthly credits
                      response[:client].add_credits(credits_amt: response[:client].current_mo_credits.to_d)
                    else
                      # trial credits
                      response[:client].add_credits(credits_amt: response[:client].trial_credits.to_d)
                    end
                  else
                    # startup charges were NOT successful
                    response = { success: false, client: nil, error_message: 'Credit card could NOT be charged.' }
                    Rails.logger.info "NewClient.create: #{{ response: }.inspect} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"
                    raise ActiveRecord::Rollback, "ActiveRecord::Rollback: #{response[:error_message]}"
                  end
                else
                  response[:client].advance_pmt_date!
                end

                # delete onetime packages
                package.destroy if package.onetime
                package_page.destroy if package_page.onetime

                Rails.logger.info "NewClient.create-created: #{{ client_id: response[:client]&.id, name: response[:client].name, mo_charge: response[:client].mo_charge }.inspect} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"
              else
                # PackagePage was NOT found
                response = { success: false, client: nil, error_message: 'Unable to locate Package Page selected.' }
                Rails.logger.info "NewClient.create: #{{ response: }.inspect} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"
                raise ActiveRecord::Rollback, "ActiveRecord::Rollback: #{response[:error_message]}"
              end
            else
              # Package was NOT found
              response = { success: false, client: nil, error_message: 'Unable to locate Package selected.' }
              Rails.logger.info "NewClient.create: #{{ response: }.inspect} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"
              raise ActiveRecord::Rollback, "ActiveRecord::Rollback: #{response[:error_message]}"
            end
          else
            # credit card info was NOT received from processor
            response = { success: false, client: nil, error_message: result[:error_message] }
            Rails.logger.info "NewClient.create: #{{ response: }.inspect} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"
            raise ActiveRecord::Rollback, "ActiveRecord::Rollback: #{response[:error_message]}"
          end
        else
          # customer was NOT created at credit card processor
          response = { success: false, client: nil, error_message: result[:error_message] }
          Rails.logger.info "NewClient.create: #{{ response: }.inspect} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"
          raise ActiveRecord::Rollback, "ActiveRecord::Rollback: #{response[:error_message]}"
        end
      end
    rescue StandardError => e
      Rails.logger.info "NewClient.create: #{{ exception: e.message, e: e.inspect, response: response.inspect, args: args.inspect }.inspect} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"
    end

    response
  end

  # Create DLC10 brand
  #   (req) client:               (Client)
  #   (req) dlc10_brand:          (Hash)
  def self.create_dlc10_brand(args)
    client      = args.dig(:client).is_a?(Client) ? args[:client] : nil
    dlc10_brand = args.dig(:dlc10_brand).is_a?(Hash) ? args[:dlc10_brand].merge(args[:dlc10_brand][:dlc10_brand]) : {}
    dlc10_brand.delete(:dlc10_brand)
    response = { success: false, error_message: '' }

    return response unless client.is_a?(Client)

    # initialize new DLC10 Brand
    new_dlc10_brand = client.build_dlc10_brand
    new_dlc10_brand.update(
      firstname:            client.def_user&.firstname,
      lastname:             client.def_user&.lastname,
      company_name:         dlc10_brand[:legal_name],
      display_name:         dlc10_brand[:name],
      street:               client.address1,
      city:                 client.city,
      state:                client.state,
      zipcode:              client.zip,
      country:              dlc10_brand[:country],
      phone:                client.phone,
      email:                client.def_user&.email,
      entity_type:          dlc10_brand[:entity_type],
      ein:                  dlc10_brand[:ein],
      ein_country:          dlc10_brand[:ein_country],
      stock_symbol:         dlc10_brand[:stock_symbol],
      stock_exchange:       dlc10_brand[:stock_exchange],
      support_email:        dlc10_brand[:support_email],
      vertical:             dlc10_brand[:vertical],
      website:              dlc10_brand[:website],
      alt_business_id:      dlc10_brand[:alt_business_id],
      alt_business_id_type: dlc10_brand[:alt_business_id_type],
      brand_relationship:   'SMALL_ACCOUNT'
    )
    new_dlc10_brand
  end

  # create new Contact (Support) for New Client
  # NewClient.create_support_contact(client: Client)
  def self.create_support_contact(args)
    client   = args.dig(:client)
    response = { success: false, contact: nil, error_message: '' }

    return response unless client.is_a?(Client)

    # create new Contact
    if (response[:contact] = client.contacts.create(firstname: 'Chiirp', lastname: 'Support', email: 'support@chiirp.com'))
      response[:success] = true
      response[:contact].contact_phones.create(phone: '8017539312', label: 'mobile')
    end

    response
  end

  # create a new User for new Client
  # result = NewClient.create_user( client: Client, user: Hash )
  def self.create_user(args)
    client   = args.dig(:client).is_a?(Client) ? args[:client] : nil
    user     = args.dig(:user).is_a?(Hash) ? args[:user] : {}
    response = { success: false, user: nil, error_message: '' }

    user[:phone] = client.phone if user[:phone].to_s.empty? && client.phone.present?

    # initialize new User
    new_user = client.users.new(user)
    new_user.skip_password_validation = true

    if new_user.save
      response[:success] = true
      response[:user]    = new_user
    else
      response[:error_message] = 'User could NOT be created.'
    end

    response
  end

  # import Campaigns & CampaignGroups for new Client
  # result = NewClient.import_campaigns( client: Client, package: Package )
  def self.import_campaigns(args)
    client   = args.dig(:client).is_a?(Client) ? args[:client] : nil
    package  = args.dig(:package).is_a?(Package) ? args[:package] : nil
    response = { success: true, error_message: '' }

    package&.package_campaigns&.each do |package_campaign|
      begin
        if package_campaign.campaign_id
          package_campaign.campaign.copy(new_client_id: client.id)
        elsif package_campaign.campaign_group_id
          package_campaign.campaign_group.copy(new_client_id: client.id)
        end
      rescue StandardError => e
        if package_campaign.campaign_id
          campaign_id              = package_campaign.campaign_id
          campaign_name            = package_campaign.campaign.name
          campaign_group_id        = 0
          campaign_group_name      = ''
          response[:error_message] = "Unable to copy Campaign: #{campaign_name}."
        elsif package_campaign.campaign_group_id
          campaign_id              = 0
          campaign_name            = ''
          campaign_group_id        = package_campaign.campaign_group_id
          campaign_group_name      = package_campaign.campaign_group.name
          response[:error_message] = "Unable to copy Campaign Group: #{campaign_group_name}."
        end

        Rails.logger.info "NewClient.import_campaigns: #{{
          exception:           e.message,
          e:                   e.inspect,
          new_client:          "#{client.name} (#{client.id})",
          package:             "#{package.name} (#{package.id})",
          package_campaign_id: package_campaign.id,
          campaign:            "#{campaign_name} (#{campaign_id})",
          campaign_group:      "#{campaign_group_name} (#{campaign_group_id})",
          args:                args.inspect
        }.inspect} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"
        next
      end
    end

    response
  end

  # send new user invitation email/text
  # result = NewClient.send_invite( client: Client, user: User )
  def self.send_invite(args)
    client = args.dig(:client).is_a?(Client) ? args[:client] : nil
    user   = args.dig(:user).is_a?(User) ? args[:user] : nil

    # send User login invitation
    I18n.with_locale(client.tenant) do
      tenant_app_host     = I18n.t("tenant.#{Rails.env}.app_host")
      tenant_app_protocol = I18n.t('tenant.app_protocol')

      ActionMailer::Base.default_url_options = { host: tenant_app_host, protocol: tenant_app_protocol }
      user.invite!(User.find_by(email: I18n.t("tenant.#{Rails.env}.key_user")))

      text_content        = I18n.t('devise.text.invitation_instructions.hello').gsub('%{firstname}', user.firstname)
      text_content       += " - #{I18n.t('devise.text.invitation_instructions.someone_invited_you')}"
      text_content       += " #{I18n.t('devise.text.invitation_instructions.accept')}"
      text_content       += " #{Rails.application.routes.url_helpers.accept_user_invitation_url(invitation_token: user.raw_invitation_token, host: tenant_app_host, protocol: tenant_app_protocol)}"

      user.delay(
        priority: DelayedJob.job_priority('send_text_to_user'),
        queue:    DelayedJob.job_queue('send_text_to_user'),
        user_id:  user.id,
        process:  'send_text_to_user'
      ).send_text(
        content:   text_content,
        automated: true,
        msg_type:  'textoutuser'
      )
    end
  end

  # add Client.user to Corporate account then start Campaigns, apply Tags and add to Groups
  # result = NewClient.corporate_contact( client: Client, package: Package )
  def self.corporate_contact(args = {})
    client   = args.dig(:client).is_a?(Client) ? args[:client] : nil
    package  = args.dig(:package).is_a?(Package) ? args[:package] : nil
    response = { success: false, error_message: '' }

    corp_contact = client.create_corp_contact

    if corp_contact
      # corporate Contact was found
      corp_contact.process_actions(
        campaign_id:       package&.campaign_id,
        group_id:          package&.group_id,
        stage_id:          package&.stage_id,
        tag_id:            package&.tag_id,
        stop_campaign_ids: package&.stop_campaign_ids
      )

      response[:success] = true
    else
      # corporate Contact was NOT found
      response[:error_message] = 'Unable to set Corporate Contact.'
    end

    response
  end

  # update a Client client_token from a card_token
  # NewClient.update_client_token_from_card_token()
  #   (req) client_id: (String) - credit card processor client_token
  #   (req) card_id:   (String)
  def self.update_client_token_from_card_token(args)
    client_id = args.dig(:client_id).to_s
    card_id   = args.dig(:card_id).to_s

    if client_id.present? && card_id.present?

      Client.where('clients.data @> ?', { card_token: card_id }.to_json).find_each do |client|
        client.update(client_token: client_id)
      end
    end

    true
  end
end
