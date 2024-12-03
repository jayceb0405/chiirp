# frozen_string_literal: true

# app/lib/credit_card/authorize_api.rb
module CreditCard
  class AuthorizeApi
    include AuthorizeNet::API

    # charge a credit card using Authorize.Net
    # result = CreditCard::AuthorizeApi.new.charge_card(tenant: String, client_id: String, amount: Decimal)
    #   (req) tenant:       (String)
    #   (req) client_id: (String)
    #   (req) amount:       (Decimal)
    #   (opt) description:  (String)
    def charge_card(args)
      tenant = args.include?(:tenant) && args[:tenant].to_s.present? ? args[:tenant].to_s : 'chiirp'
      client_id = args.include?(:client_id) ? args[:client_id].to_s : ''
      amount       = args.include?(:amount) ? args[:amount].to_d : 0
      description  = args.include?(:description) ? args[:description].to_s : ''
      response     = { success: false, trans_id: '', amount: 0, error_code: '', error_message: '' }

      if client_id.present? && amount.positive?
        prev_card_info = card(client_id:)

        if prev_card_info[:success] && prev_card_info[:card_id].present?
          transaction = Transaction.new(Rails.application.credentials[:authorizenet][tenant.to_sym][:login_id], Rails.application.credentials[:authorizenet][tenant.to_sym][:transaction_key], gateway: (Rails.env.production? ? :production : :sandbox))

          request = CreateTransactionRequest.new

          request.transactionRequest = TransactionRequestType.new
          request.transactionRequest.amount = amount
          request.transactionRequest.transactionType = TransactionTypeEnum::AuthCaptureTransaction
          # request.transactionRequest.order = OrderType.new("invoiceNumber#{(SecureRandom.random_number*1000000).round(0)}","Order Description")
          request.transactionRequest.profile = CustomerProfilePaymentType.new
          request.transactionRequest.profile.customerProfileId = client_id
          request.transactionRequest.profile.paymentProfile = PaymentProfile.new(prev_card_info[:card_id])

          result = transaction.create_transaction(request)

          if result.nil?
            ProcessError::Report.send(
              error_code:    'Unable to create transaction.',
              error_message: 'CreditCard::AuthorizeNet.charge_card',
              variables:     {
                client_id:,
                amount:,
                description:,
                prev_card_info: prev_card_info.inspect,
                request:        request.inspect,
                result:         result.inspect
              },
              file:          __FILE__,
              line:          __LINE__
            )
          elsif result.messages.resultCode == MessageTypeEnum::Ok
            if !result.transactionResponse.nil? && !result.transactionResponse.messages.nil?
              # Rails.logger.info "Success, Auth Code: #{result.transactionResponse.authCode}"
              # Rails.logger.info "Transaction Response code: #{result.transactionResponse.responseCode}" # 1 - Approved / 2 - Declined / 3 - Error / 4 - Held for Review
              # Rails.logger.info "Transaction ID: #{result.transactionResponse.transId}"
              # Rails.logger.info "Code: #{result.transactionResponse.messages.messages[0].code}"
              # Rails.logger.info "Description: #{result.transactionResponse.messages.messages[0].description}"
              response[:trans_id] = result.transactionResponse.transId

              if result.transactionResponse.responseCode.to_i == 1
                response[:success] = true

                if result.transactionResponse.splitTenderPayments
                  result.transactionResponse.splitTenderPayments.each do |split_tender_payment|
                    response[:amount] += split_tender_payment.approvedAmount.to_d
                  end
                else
                  response[:amount] = amount
                end
              else
                response[:error_code] = result.transactionResponse.responseCode
                response[:error_message] = ['', '', 'Declined', 'Error', 'Held For Review'][result.transactionResponse.responseCode.to_i]
              end
            else
              if result.transactionResponse.errors.nil?
                response[:error_code] = result.transactionResponse.messages[0].code
                response[:error_message] = result.transactionResponse.messages[0].description
              else
                response[:error_code] = result.transactionResponse.errors.errors[0].errorCode
                response[:error_message] = result.transactionResponse.errors.errors[0].errorText
              end

              ProcessError::Report.send(
                error_code:    'Unable to create transaction.',
                error_message: 'CreditCard::AuthorizeNet.charge_card',
                variables:     {
                  client_id:,
                  amount:,
                  description:,
                  prev_card_info: prev_card_info.inspect,
                  error_code:     response[:error_code],
                  error_message:  response[:error_message],
                  request:        request.inspect,
                  result:         result.inspect
                },
                file:          __FILE__,
                line:          __LINE__
              )
            end
          else
            if !result.transactionResponse.nil? && !result.transactionResponse.errors.nil?
              response[:error_code] = result.transactionResponse.errors.errors[0].errorCode
              response[:error_message] = result.transactionResponse.errors.errors[0].errorText
            else
              response[:error_code] = result.messages.messages[0].code
              response[:error_message] = result.messages.messages[0].text
            end

            ProcessError::Report.send(
              error_code:    'Unable to create transaction.',
              error_message: 'CreditCard::AuthorizeNet.charge_card',
              variables:     {
                client_id:,
                amount:,
                description:,
                prev_card_info: prev_card_info.inspect,
                error_code:     response[:error_code],
                error_message:  response[:error_message],
                request:        request.inspect,
                result:         result.inspect
              },
              file:          __FILE__,
              line:          __LINE__
            )
          end
        else
          ProcessError::Report.send(
            error_code:    'Unable to create transaction.',
            error_message: 'CreditCard::AuthorizeNet.charge_card',
            variables:     {
              client_id:,
              amount:,
              description:,
              prev_card_info: prev_card_info.inspect
            },
            file:          __FILE__,
            line:          __LINE__
          )
        end
      else
        ProcessError::Report.send(
          error_code:    'Unable to create transaction.',
          error_message: 'CreditCard::AuthorizeNet.charge_card',
          variables:     {
            client_id:,
            amount:,
            description:
          },
          file:          __FILE__,
          line:          __LINE__
        )
      end

      response
    end

    # create a customer from a single use token using Authorize.Net
    # result = CreditCard::AuthorizeApi.new.customer_create(tenant: String, card_id: String, cust_description: String)
    #   (req) card_id:       (String)
    #   (req) cust_description: (String)
    #   (req) tenant:           (String)
    def customer_create(args)
      tenant           = args.include?(:tenant) && args[:tenant].to_s.present? ? args[:tenant].to_s : 'chiirp'
      client_id        = args.include?(:client_id) ? args[:client_id].to_i.to_s : ''
      card_id = args.include?(:card_id) ? args[:card_id].to_s : ''
      cust_description = args.include?(:cust_description) ? args[:cust_description].to_s : ''
      response         = { success: false, card_id: '', client_id: '', error_code: '', error_message: '' }

      if client_id.present? && card_id.present?
        transaction = Transaction.new(Rails.application.credentials[:authorizenet][tenant.to_sym][:login_id], Rails.application.credentials[:authorizenet][tenant.to_sym][:transaction_key], gateway: (Rails.env.production? ? :production : :sandbox))

        # Build the payment object
        payment = PaymentType.new
        payment.opaqueData = OpaqueDataType.new('COMMON.ACCEPT.INAPP.PAYMENT', card_id)

        # rubocop:disable Naming/VariableName

        # Build an address object
        billTo = CustomerAddressType.new

        # build a payment profile to send with the request
        paymentProfile = CustomerPaymentProfileType.new
        paymentProfile.payment = payment
        paymentProfile.billTo = billTo

        # Build the request object
        request = CreateCustomerProfileRequest.new

        # Build the profile object containing the main information about the customer profile
        request.profile = CustomerProfileType.new
        request.profile.merchantCustomerId = client_id
        request.profile.description = cust_description

        # Add the payment profile and shipping profile defined previously
        request.profile.paymentProfiles = [paymentProfile]

        # rubocop:enable Naming/VariableName

        # request.profile.shipToList = [shippingAddress]
        request.validationMode = if Rails.env.production?
                                   ValidationModeEnum::LiveMode
                                 else
                                   ValidationModeEnum::TestMode
                                 end

        result = transaction.create_customer_profile(request)

        # Rails.logger.info "Transaction Request: #{request.inspect} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"
        # Rails.logger.info "Transaction Result: #{result.inspect} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"
        # Rails.logger.info "Transaction Result Code: #{result.messages.resultCode.inspect} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"

        if result.nil?
          ProcessError::Report.send(
            error_code:    'Customer profile creation is NULL.',
            error_message: 'CreditCard::AuthorizeNet.customer_create',
            variables:     {
              client_id:,
              card_id:,
              cust_description:,
              request:          request.inspect,
              result:           result.inspect
            },
            file:          __FILE__,
            line:          __LINE__
          )
        elsif result.messages.resultCode == MessageTypeEnum::Ok
          response[:success] = true
          response[:client_id] = result.customerProfileId
          response[:card_id]   = result.customerPaymentProfileIdList.numericString[0]
        # Rails.logger.info "Successfully created a customer profile with id: #{result.customerProfileId} File: #{__FILE__} - Line: #{__LINE__}"
        # Rails.logger.info "  Customer Payment Profile Id List:"
        # result.customerPaymentProfileIdList.numericString.each do |id|
        # Rails.logger.info "    #{id}"
        # end
        # Rails.logger.info "  Customer Shipping Address Id List:"
        # result.customerShippingAddressIdList.numericString.each do |id|
        # Rails.logger.info "    #{id}"
        # end

        else
          ProcessError::Report.send(
            error_code:    'Failed to create a new customer profile.',
            error_message: 'CreditCard::AuthorizeNet.customer_create',
            variables:     {
              client_id:,
              card_id:,
              cust_description:,
              code:             result.messages.messages[0].code,
              text:             result.messages.messages[0].text,
              request:          request.inspect,
              result:           result.inspect
            },
            file:          __FILE__,
            line:          __LINE__
          )
        end
      else
        ProcessError::Report.send(
          error_code:    'Customer profile creation is NULL.',
          error_message: 'CreditCard::AuthorizeNet.customer_create',
          variables:     {
            client_id:,
            card_id:,
            cust_description:
          },
          file:          __FILE__,
          line:          __LINE__
        )
      end

      response
    end

    # delete a customer with a customer token using Authorize.Net
    # result = CreditCard::AuthorizeApi.new.customer_delete(tenant: String, client_id: String)
    #   (req) tenant:       (String)
    #   (req) client_id: (String)
    def customer_delete(args)
      tenant = args.include?(:tenant) && args[:tenant].to_s.present? ? args[:tenant].to_s : 'chiirp'
      client_id = args.include?(:client_id) ? args[:client_id].to_s : ''
      response = { success: false, client_id:, error_code: '', error_message: '' }

      if client_id.present?
        transaction = Transaction.new(Rails.application.credentials[:authorizenet][tenant.to_sym][:login_id], Rails.application.credentials[:authorizenet][tenant.to_sym][:transaction_key], gateway: (Rails.env.production? ? :production : :sandbox))

        request = DeleteCustomerProfileRequest.new
        request.customerProfileId = client_id

        result = transaction.delete_customer_profile(request)

        if result.messages.resultCode == MessageTypeEnum::Ok
          response[:success] = true
          response[:client_id] = ''
        else
          ProcessError::Report.send(
            error_code:    'Failed to delete customer profile.',
            error_message: 'CreditCard::AuthorizeNet.customer_delete',
            variables:     {
              client_id:,
              code:      result.messages.messages[0].code,
              text:      result.messages.messages[0].text,
              request:   request.inspect,
              result:    result.inspect
            },
            file:          __FILE__,
            line:          __LINE__
          )
        end
      else
        ProcessError::Report.send(
          error_code:    'Failed to delete customer profile.',
          error_message: 'CreditCard::AuthorizeNet.customer_delete',
          variables:     {
            client_id:
          },
          file:          __FILE__,
          line:          __LINE__
        )
      end

      response
    end

    # update a customer with a customer token using Authorize.Net
    # result = CreditCard::AuthorizeApi.new.customer_update(tenant: String, client_id: String, card_id: String, cust_description: String)
    #   (req) tenant:           (String)
    #   (req) client_id:     (String)
    #   (req) card_id:       (String)
    #   (req) cust_description: (String)
    def customer_update(args)
      tenant = args.include?(:tenant) && args[:tenant].to_s.present? ? args[:tenant].to_s : 'chiirp'
      client_id     = args.include?(:client_id) ? args[:client_id].to_s : ''
      card_id       = args.include?(:card_id) ? args[:card_id].to_s : ''
      cust_description = args.include?(:cust_description) ? args[:cust_description].to_s : ''
      response         = { success: false, card_id: '', client_id:, error_code: '', error_message: '' }

      if client_id.present? && card_id.present?
        prev_card_info = card(client_id:)

        if prev_card_info[:success] && prev_card_info[:card_id].present?
          transaction = Transaction.new(Rails.application.credentials[:authorizenet][tenant.to_sym][:login_id], Rails.application.credentials[:authorizenet][tenant.to_sym][:transaction_key], gateway: (Rails.env.production? ? :production : :sandbox))

          request = UpdateCustomerPaymentProfileRequest.new

          # Build the payment object
          payment = PaymentType.new
          payment.opaqueData = OpaqueDataType.new('COMMON.ACCEPT.INAPP.PAYMENT', card_id)

          profile = CustomerPaymentProfileExType.new(nil, nil, payment, nil, nil)

          request.paymentProfile = profile
          request.customerProfileId = client_id
          profile.customerPaymentProfileId = prev_card_info[:card_id]

          result = transaction.update_customer_payment_profile(request)

          if result.messages.resultCode == MessageTypeEnum::Ok
            response[:success] = true
            response[:card_id] = request.paymentProfile.customerPaymentProfileId
          else
            ProcessError::Report.send(
              error_code:    'Failed to update customer profile.',
              error_message: 'CreditCard::AuthorizeNet.customer_update',
              variables:     {
                client_id:,
                card_id:,
                cust_description:,
                code:             result.messages.messages[0].code,
                text:             result.messages.messages[0].text,
                request:          request.inspect,
                result:           result.inspect
              },
              file:          __FILE__,
              line:          __LINE__
            )
          end
        end
      end

      response
    end

    # get credit card info from single use token using Authorize.Net
    # result = CreditCard::AuthorizeApi.new.card(tenant: String, card_id: String)
    #   (req) tenant:       (String)
    #   (req) card_id:   (String)
    def card(args)
      tenant = args.include?(:tenant) && args[:tenant].to_s.present? ? args[:tenant].to_s : 'chiirp'
      client_id = args.include?(:client_id) ? args[:client_id].to_s : ''
      response = { success: false, card_id: '', card_brand: '', card_last4: '', card_exp_month: '', card_exp_year: '', error_code: '', error_message: '' }

      if client_id.present?
        transaction = Transaction.new(Rails.application.credentials[:authorizenet][tenant.to_sym][:login_id], Rails.application.credentials[:authorizenet][tenant.to_sym][:transaction_key], gateway: (Rails.env.production? ? :production : :sandbox))

        request = GetCustomerProfileRequest.new
        request.customerProfileId = client_id
        request.unmaskExpirationDate = true

        result = transaction.get_customer_profile(request)

        if result.messages.resultCode == MessageTypeEnum::Ok
          # Rails.logger.info "result: #{result.inspect} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"
          expiration = result.profile.paymentProfiles[0].payment.creditCard.expirationDate

          response[:success] = true
          response[:card_id] = result.profile.paymentProfiles[0].customerPaymentProfileId.to_s
          response[:card_brand]     = result.profile.paymentProfiles[0].payment.creditCard.cardType.to_s
          response[:card_last4]     = result.profile.paymentProfiles[0].payment.creditCard.cardNumber.to_s.delete('X')
          response[:card_exp_month] = expiration.split('-')[1].to_s
          response[:card_exp_year]  = expiration.split('-')[0].to_s
        else
          ProcessError::Report.send(
            error_code:    'Customer profile lookup failed.',
            error_message: 'CreditCard::AuthorizeNet.card',
            variables:     {
              client_id:,
              result_code: result.messages.messages[0].code.inspect,
              tesult_text: result.messages.messages[0].text.inspect,
              request:     request.inspect,
              result:      result.inspect
            },
            file:          __FILE__,
            line:          __LINE__
          )
        end
      else
        ProcessError::Report.send(
          error_code:    'Customer profile lookup failed.',
          error_message: 'CreditCard::AuthorizeNet.card',
          variables:     {
            card_id:
          },
          file:          __FILE__,
          line:          __LINE__
        )
      end

      response
    end
  end
end
