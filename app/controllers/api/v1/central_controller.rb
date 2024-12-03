# frozen_string_literal: true

# app/controllers/api/v1/central_controller.rb
module Api
  module V1
    # API access to Message Central
    class CentralController < ApiController
      skip_before_action :verify_authenticity_token, only: %i[init show central]
      after_action only: %i[init show central] do
        allow_servicemonster_iframe('*')
      end

      # /api/v1/central
      # api_v1_central_path
      # api_v1_central_url
      def central
        render json: { message: 'Unauthorized' }, layout: false, status: :unauthorized and return false unless request.headers[:Authorization] == "Basic #{basic_auth}"
        render json: { message: 'Company Not Found' }, layout: false, status: :not_found and return false unless (client_api_integration = ClientApiIntegration.where(target: 'servicemonster', name: '').find_by('data @> ?', { company: { companyID: params.permit(:companyID).dig(:companyID) } }.to_json))
        # render json: { message: 'Employee Not Found' }, layout: false, status: 404 and return false unless (@current_user = client_api_integration.client.users.find_by(id: client_api_integration.employees.dig(params.permit(:employeeID).dig(:employeeID))))
        render json: { message: 'Employee Log In Expired' }, layout: false, status: :unauthorized and return false unless current_user.current_sign_in_at >= 14.days.ago
        render json: { message: 'Employee Suspended' }, layout: false, status: :unauthorized and return false if current_user.suspended?

        client           = client_api_integration.client
        sanitized_params = params_account(client.time_zone)

        phones = {}
        phones[sanitized_params[:phone1]] = sanitized_params[:phone1Label] if sanitized_params.dig(:phone1).present?
        phones[sanitized_params[:phone2]] = sanitized_params[:phone2Label] if sanitized_params.dig(:phone2).present?
        phones[sanitized_params[:phone3]] = sanitized_params[:phone3Label] if sanitized_params.dig(:phone3).present?
        mobile_phone_index                = [sanitized_params.dig(:phone1Label), sanitized_params.dig(:phone2Label), sanitized_params.dig(:phone3Label)].map(&:downcase).index('mobile')

        lead_source = Integration::Servicemonster.convert_sm_lead_source_id(client_api_integration, sanitized_params.dig(:leadSourceID))

        if (@contact = Contact.find_or_initialize_by_phone_or_email_or_ext_ref(client_id: client.id, phones:, emails: [sanitized_params.dig(:email).to_s], ext_refs: { 'servicemonster' => sanitized_params.dig(:accountID).to_s }))
          @contact.update(
            firstname:      sanitized_params.dig(:firstName).to_s,
            lastname:       sanitized_params.dig(:lastName).to_s,
            address1:       sanitized_params.dig(:address1).to_s,
            address2:       sanitized_params.dig(:address2).to_s,
            city:           sanitized_params.dig(:city).to_s,
            state:          sanitized_params.dig(:state).to_s,
            zipcode:        sanitized_params.dig(:zip).to_s,
            ok2text:        if mobile_phone_index
                              sanitized_params.dig(:"canText#{mobile_phone_index + 1}") ? 1 : 0
                            else
                              1
                            end,
            ok2email:       1,
            lead_source_id: lead_source&.id
          )
        end

        respond_to do |format|
          format.js { render partial: 'central/v1/show', locals: { cards: %w[conversation] } }
          format.html { render json: { message: 'Bad Request - Expected Javascript Format' }, layout: false, status: :bad_request }
        end
      end

      # /api/v1/central/init
      # api_v1_central_init_path
      # api_v1_central_init_url
      def init
        respond_to do |format|
          format.js { render partial: 'central/v1/frame_init' }
          format.html { render json: { message: 'Bad Request - Expected Javascript Format' }, layout: false, status: :bad_request }
        end
      end

      # /api/v1/central/show
      # api_v1_central_show_path
      # api_v1_central_show_url
      def show
        respond_to do |format|
          format.js { render js: "window.location = '/'" }
          format.html { render 'central/v1/show', layout: 'api_v1_message_central', status: :ok, locals: { rendered_by: 'frame' } }
        end
      end

      private

      def basic_auth
        Base64.urlsafe_encode64("#{user_name}:#{password}").strip
      end

      def params_account(time_zone)
        sanitized_params = params.permit(:accountID, :accountName, :accountSubType, :accountType, :acquisitionDate, :active, :address1, :address2, :alert, :city, :comment, :commercial, :companyID, :companyKey, :companyName, :country, :county, :courierRoute, :createdBy, :createdOn, :doNotCall, :doNotEmail, :doNotMail, :email, :copyLeadSourceToNewOrders, :externalRefID, :fax, :firstName, :flagForReview, :lastName, :lastStatementDate, :nextJobDate, :lastJobDate, :lastJobAmount, :leadSourceID, :leadSourceNote, :accountReferralID, :note, :parentAccountID, :paymentTerm, :phone1, :phone1Label, :canText1, :phone2, :phone2Label, :canText2, :phone3, :phone3Label, :canText3, :reference, :salutation, :securityGroup, :siteReference, :state, :taxExempt, :taxID, :zip, :timeStamp, :checkForDuplicates, :userName)

        sanitized_params[:active]                    = sanitized_params[:active].to_bool if sanitized_params.include?(:active)
        sanitized_params[:acquisitionDate]           = Chronic.parse(sanitized_params[:acquisitionDate])&.to_date if sanitized_params.include?(:acquisitionDate)
        sanitized_params[:alert]                     = sanitized_params[:alert].to_bool if sanitized_params.include?(:alert)
        sanitized_params[:canText1]                  = sanitized_params[:canText1].to_bool if sanitized_params.include?(:canText1)
        sanitized_params[:canText2]                  = sanitized_params[:canText2].to_bool if sanitized_params.include?(:canText2)
        sanitized_params[:canText3]                  = sanitized_params[:canText3].to_bool if sanitized_params.include?(:canText3)
        sanitized_params[:commercial]                = sanitized_params[:commercial].to_bool if sanitized_params.include?(:commercial)
        sanitized_params[:copyLeadSourceToNewOrders] = sanitized_params[:copyLeadSourceToNewOrders].to_bool if sanitized_params.include?(:copyLeadSourceToNewOrders)
        sanitized_params[:createdOn]                 = Time.use_zone(time_zone) { Chronic.parse(sanitized_params[:createdOn]) }&.utc if sanitized_params.include?(:createdOn)
        sanitized_params[:doNotCall]                 = sanitized_params[:doNotCall].to_bool if sanitized_params.include?(:doNotCall)
        sanitized_params[:doNotEmail]                = sanitized_params[:doNotEmail].to_bool if sanitized_params.include?(:doNotEmail)
        sanitized_params[:doNotMail]                 = sanitized_params[:doNotMail].to_bool if sanitized_params.include?(:doNotMail)
        sanitized_params[:flagForReview]             = sanitized_params[:flagForReview].to_bool if sanitized_params.include?(:flagForReview)
        sanitized_params[:lastJobAmount]             = sanitized_params[:lastJobAmount].to_d if sanitized_params.include?(:lastJobAmount)
        sanitized_params[:lastJobDate]               = Time.use_zone(time_zone) { Chronic.parse(sanitized_params[:lastJobDate]) }&.utc if sanitized_params.include?(:lastJobDate)
        sanitized_params[:lastStatementDate]         = Time.use_zone(time_zone) { Chronic.parse(sanitized_params[:lastStatementDate]) }&.utc if sanitized_params.include?(:lastStatementDate)
        sanitized_params[:nextJobDate]               = Time.use_zone(time_zone) { Chronic.parse(sanitized_params[:nextJobDate]) }&.utc if sanitized_params.include?(:nextJobDate)
        sanitized_params[:taxExempt]                 = sanitized_params[:taxExempt].to_bool if sanitized_params.include?(:taxExempt)
        sanitized_params[:timeStamp]                 = Time.use_zone(time_zone) { Chronic.parse(sanitized_params[:timeStamp]) }&.utc if sanitized_params.include?(:timeStamp)

        sanitized_params
      end

      def password
        Rails.application.credentials[:servicemonster][:api][:password]
      end

      def user_name
        Rails.application.credentials[:servicemonster][:api][:user_name]
      end
    end
  end
end
