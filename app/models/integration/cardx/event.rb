# frozen_string_literal: true

# app/models/integration/cardx/event.rb
module Integration
  module Cardx
    class Event
      include Cardx::ReferencesDestroyed

      # client_id = xx
      # client_api_integration = ClientApiIntegration.find_by(client_id: client_id, target: 'cardx', name: ''); cx_model = Integration::Cardx::Event.new(client_api_integration_id: client_api_integration.id)

      # initialize Cardx event
      # cr_event_client = Integration::Cardx::Event.new()
      #   (req) client_api_integration_id: (Integer)
      #   (opt) customer_email:            (String)
      #   (opt) customer_name:             (String)
      #   (opt) customer_city:             (String)
      #   (opt) customer_state:            (String)
      #   (opt) gateway_account:           (String)
      #   (opt) transaction_amount:        (Float)
      #   (opt) authorization_code:        (String)
      #   (opt) date:                      (Time)
      #   (opt) tags:                      (Array[String])
      #   (opt) keywords:                  (Array[String])
      def initialize(args = {})
        @client_api_integration_id  = args.dig('client_api_integration_id') || args.dig(:client_api_integration_id)
        @client_api_integration     = ClientApiIntegration.find_by(id: @client_api_integration_id)

        @customer_email             = args.dig('email')
        @customer_name              = args.dig('name')
        @customer_city              = args.dig('city')
        @customer_state             = args.dig('state')

        @gateway_account            = args.dig('gateway_account')

        @card_type                  = args.dig('card_type') || 'credit'
        @transaction_amount         = args.dig('transaction_amount') || 0.0
        @surcharge_amount           = args.dig('surcharge_amount') || 0.0
        @authorization_code         = args.dig('authorization_code')
        @date                       = args.dig('date')

        @contact_id                 = args.dig('contact_id')
        @contact                    = Contact.find_by(id: @contact_id) if @contact_id.present?

        @raw_params                 = args.dig('raw_params')

        @job_id                     = args.dig('job_id')
        @job                        = @contact.jobs.find_by(id: @job_id) if @contact && @job_id.present?
      end

      # process the event received from CardX
      # cr_event_client.process
      def process
        return unless ok_to_process

        # do not go any further if there is no contact
        unless @contact
          Rails.logger.info "Integration::Cardx::Event.process: CardX Integration Event: No contact found: #{{ client_api_integration_id: @client_api_integration.id, params: @raw_params.inspect }.inspect} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"

          return
        end

        # save payment info to cardx transactions
        @client_api_integration.client.payment_transactions.create(
          target:           'cardx',
          payment_type:     @card_type,
          contact_jobs_id:  @job&.id,
          amount_total:,
          amount_requested: @transaction_amount,
          amount_fees:      @surcharge_amount,
          transacted_at:    @date
        )

        # # create a contact no matter what
        # @contact ||= Contact.find_or_initialize_by_phone_or_email_or_ext_ref(client_id: @client_api_integration.client_id, emails: [@customer_email])

        # if @contact.new_record?
        #   @contact.firstname = @customer_name.parse_name[:firstname]
        #   @contact.lastname = @customer_name.parse_name[:lastname] if @customer_name
        #   @contact.city = @customer_city if @customer_city
        #   @contact.state = @customer_state if @customer_state
        #   @contact.save
        # end

        # save raw param data
        @contact.raw_posts.create(ext_source: 'cardx', ext_id: 'payment', data: @raw_params)

        # save payment info to message central
        @contact.messages.create(
          message:      "Payment #{ActionController::Base.helpers.number_to_currency(@transaction_amount)}",
          msg_type:     'payment',
          from_phone:   @contact.primary_phone&.phone,
          status:       'received',
          to_phone:     '',
          num_segments: 0,
          automated:    false
        )

        if @job.present?
          # update funds recieved in job
          @job.payments_received += @transaction_amount
          @job.save

          # process ServiceTitan integration
          process_service_titan if @client_api_integration.service_titan&.dig('post_payments')&.to_bool
        end

        @client_api_integration.events.each { |event| process_event(event.deep_symbolize_keys, @contact) }
      end

      private

      def ok_to_process
        @client_api_integration.present? && @customer_email.present?
      end

      def amount_total
        @transaction_amount + @surcharge_amount
      end

      # process a chiirp client integration event
      # (req) event:     (Hash)
      def process_event(event, contact)
        return unless ok_to_process_remaining_balance?(event)

        contact.process_actions(
          campaign_id:       event.dig(:action, :campaign_id).to_i,
          group_id:          event.dig(:action, :group_id).to_i,
          stage_id:          event.dig(:action, :stage_id).to_i,
          tag_id:            event.dig(:action, :tag_id).to_i,
          stop_campaign_ids: event.dig(:action, :stop_campaign_ids)&.compact_blank,
          contact_job_id:    @job&.id
        )
      end

      def process_service_titan
        client_api_integration = ClientApiIntegration.find_by(client_id: @client_api_integration.client_id, target: 'servicetitan', name: '')

        return false unless client_api_integration

        st_model = Integration::Servicetitan::V2::Base.new(client_api_integration)
        return unless st_model.valid_credentials?

        st_client = Integrations::ServiceTitan::Base.new(client_api_integration.credentials)
        st_client.post_payment(
          amount_paid:   @transaction_amount,
          st_invoice_id: @job.ext_invoice_id,
          st_type_id:    @client_api_integration.service_titan.dig('payment_type'),
          auth_code:     @authorization_code,
          comment:       @client_api_integration.service_titan.dig('comment'),
          paid_at:       @date
        )
      end

      def ok_to_process_remaining_balance?(event)
        return true unless event[:remaining_balance_operator]
        return false unless @job # if remaining_balance_operator is set, then we must have a job to check against

        case event[:remaining_balance_operator]
        when 'lte'
          @job.remaining_balance <= event[:remaining_balance]
        when 'gte'
          @job.remaining_balance >= event[:remaining_balance]
        end
      end
    end
  end
end
