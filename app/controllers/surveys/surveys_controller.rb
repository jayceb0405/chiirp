# frozen_string_literal: true

# app/controllers/surveys/surveys_controller.rb
module Surveys
  class SurveysController < ApplicationController
    class SurveysControllerError < StandardError; end

    before_action :authenticate_user!, except: %i[show update_contact]
    before_action :authorize_user!, except: %i[show update_contact]
    before_action :survey, only: %i[copy destroy edit update update_background_image update_logo_image]
    before_action :survey_by_key, only: %i[show update_contact], unless: :params_include_page_name?
    before_action :survey_screen_by_key, only: %i[show update_contact], unless: :params_include_page_name?
    before_action :survey_by_page_name, only: %i[show update_contact], if: :params_include_page_name?
    before_action :user_api_integration_for_activeprospect, only: %i[show update_contact]

    # (PATCH) copy a Surveys::Survey
    # /surveys/copy/:id
    # surveys_copy_path(:id)
    # surveys_copy_url(:id)
    def copy
      @survey.copy(@survey.client_id)

      render partial: 'surveys/js/show', locals: { cards: %w[surveys_index] }
    end

    # (DELETE) delete a Survey
    # /surveys/surveys/:id
    # surveys_survey_path(:id)
    # surveys_survey_url(:id)
    def destroy
      @survey.destroy

      render partial: 'surveys/js/show', locals: { cards: %w[surveys_index] }
    end

    # (GET) edit a Survey
    # /surveys/surveys/:id/edit
    # edit_surveys_survey_path(:id)
    # edit_surveys_survey_url(:id)
    def edit
      render partial: 'surveys/js/show', locals: { cards: %w[survey_edit] }
    end

    # (POST) import a shared Survey
    # /surveys/import
    # surveys_import_path
    # surveys_import_url
    def import
      if params.permit(:share_code).dig(:share_code).present?

        if (survey = Surveys::Survey.find_by(share_code: params.permit(:share_code).dig(:share_code)))
          @survey = survey.copy(current_user.client.id)

          if @survey
            sweetalert_success("#{::Surveys::Survey.title} Import Success!", "Hurray! '#{@survey.name}' was imported successfully.", '', { persistent: 'OK' })
          else
            sweetalert_warning('Something went wrong!', '', "Sorry, we couldn't import that #{::Surveys::Survey.title}.", { persistent: 'OK' })

            error = SurveysControllerError.new("Survey Import Error: Survey #{survey.id}")
            error.set_backtrace(BC.new.clean(caller))

            Appsignal.report_error(error) do |transaction|
              # Only needed if it needs to be different or there's no active transaction from which to inherit it
              Appsignal.set_action('Surveys::SurveysController#import')

              # Only needed if you want to set different arguments or there's no active transaction from which to inherit it
              Appsignal.add_params(params)

              Appsignal.set_tags(
                error_level: 'error',
                error_code:  0
              )
              Appsignal.add_custom_data(
                survey:     survey.inspect,
                new_survey: @survey.inspect,
                user:       {
                  id:   current_user.id,
                  name: current_user.fullname
                },
                file:       __FILE__,
                line:       __LINE__
              )
            end
          end
        else
          sweetalert_warning("#{::Surveys::Survey.title} Not Found!", 'Sorry, we couldn\'t find that share code. Please verify the code and try again.', '', { persistent: 'OK' })
        end
      else
        sweetalert_warning('Share Code Not Entered!', 'Sorry, a share code was NOT entered. Please enter the code and try again.', '', { persistent: 'OK' })
      end

      render partial: 'surveys/js/show', locals: { cards: %w[surveys_index] }
    end

    # (GET) list Surveys
    # /surveys/surveys
    # surveys_surveys_path
    # surveys_surveys_url
    def index
      respond_to do |format|
        format.js   { render partial: 'surveys/js/show', locals: { cards: %w[surveys_index] } }
        format.html { render 'surveys/index' }
      end
    end

    # (GET) initialize a new Survey
    # /surveys/surveys/new
    # new_surveys_survey_path
    # new_surveys_survey_url
    def new
      @survey = current_user.client.surveys.create(name: "New #{::Surveys::Survey.title}")

      render partial: 'surveys/js/show', locals: { cards: %w[surveys_index survey_open_new] }
    end

    # (GET) display a Survey
    # /surveys/:survey_key/:screen_key
    # survey_path(:survey_key, :screen_key)
    # survey_url(:survey_key, :screen_key)
    def show
      params_show
      save_selection

      respond_to do |format|
        format.html { render 'surveys/show', layout: false }
        format.js   { render partial: 'surveys/js/show', locals: { cards: %w[surveys_show] } }
      end
    end

    # (PATCH/PUT) upsate an existing Survey
    # /surveys/surveys/:id
    # surveys_survey_path(:id)
    # surveys_survey_url(:id)
    def update
      @survey.update(params_survey)

      render partial: 'surveys/js/show', locals: { cards: %w[survey_edit td_survey_name] }
    end

    # (POST)
    # /surveys/:survey_key/:screen_key
    # survey_contact_path(:survey_key, :screen_key)
    # survey_contact_url(:survey_key, :screen_key)
    def update_contact
      contact_data = params_contact
      contact_data[:birthdate] = Chronic.parse(contact_data[:birthdate]) if contact_data.include?(:birthdate)
      contact_data[:email]     = contact_data.dig(:email).to_s

      params_show

      @contact = Contact.find_by(id: @cid, client_id: @survey.client_id) || Contact.find_or_initialize_by_phone_or_email_or_ext_ref(client_id: @survey.client_id, phones: params_contact_phone, emails: [contact_data[:email]])
      @contact.update(
        lastname:     (contact_data.dig(:lastname) || @contact.lastname).to_s,
        firstname:    (contact_data.dig(:firstname) || @contact.firstname).to_s,
        email:        (contact_data.dig(:email) || @contact.email).to_s,
        address1:     (contact_data.dig(:address1) || @contact.address1).to_s,
        address2:     (contact_data.dig(:address2) || @contact.address2).to_s,
        city:         contact_data.dig(:city) || @contact.city.to_s,
        state:        contact_data.dig(:state) || @contact.state.to_s,
        zipcode:      contact_data.dig(:zipcode) || @contact.zipcode.to_s,
        birthdate:    contact_data.dig(:birthdate) || @contact.birthdate,
        ok2text:      (contact_data.dig(:ok2text) || 1).to_i,
        ok2email:     (contact_data.dig(:ok2email) || @contact.ok2email).to_s,
        trusted_form: {
          token:    params.dig(:xxTrustedFormToken).to_s,
          cert_url: params.dig(:xxTrustedFormCertUrl).to_s,
          ping_url: params.dig(:xxTrustedFormPingUrl).to_s
        }
      )
      @contact.update_contact_phones(params_contact_phone.map { |k, v| [k, v] })

      if @contact.errors.any?
        sweetalert_error('Sorry!', "#{@contact.errors.full_messages.join(' & ')}.", '', { persistent: 'OK' }) if @survey_screen.actions.dig('redirect_url').to_s.blank?
      else
        # save ContactCustomFields
        @contact.update_custom_fields(custom_fields: params_client_custom_fields.to_h)

        @cid = @contact.id
        save_selection

        @contact.process_actions(
          campaign_id:       @survey_screen.actions.dig('campaign_id'),
          group_id:          @survey_screen.actions.dig('group_id'),
          stage_id:          @survey_screen.actions.dig('stage_id'),
          tag_id:            @survey_screen.actions.dig('tag_id'),
          stop_campaign_ids: @survey_screen.actions.dig('stop_campaign_ids')
        )

        sweetalert_success("Thank You#{@contact.firstname.present? ? " #{@contact.firstname}" : ''}!", 'Your information was saved.', '', {}) if @survey_screen.actions.dig('redirect_url').to_s.blank?
      end

      if @survey_screen.actions.dig('redirect_screen_id').to_i.zero? && @survey_screen.actions.dig('redirect_url').to_s.present?
        # redirect to a website URL

        respond_to do |format|
          format.html { redirect_to @survey_screen.actions.dig('redirect_url').to_s, allow_other_host: true }
          format.js { render js: "window.location = '#{@survey_screen.actions.dig('redirect_url')}'" }
        end
      elsif @survey_screen.actions.dig('redirect_screen_id').to_i.positive? && (next_screen = @survey.screens.find_by(id: @survey_screen.actions.dig('redirect_screen_id').to_i))
        # redirect to the next SurveyScreen

        respond_to do |format|
          format.html { redirect_to survey_path(@survey.survey_key, next_screen.screen_key, cid: @cid), allow_other_host: true }
          format.js { render js: "window.location = '#{survey_path(@survey.survey_key, next_screen.screen_key, cid: @cid)}'" }
        end
      else
        # redirect to the first SurveyScreen

        respond_to do |format|
          format.html { redirect_to survey_path(@survey.survey_key, 0, cid: @cid), allow_other_host: true }
          format.js { render js: "window.location = '#{survey_path(@survey.survey_key, 0, cid: @cid)}'" }
        end
      end
    end

    # (PATCH)
    # /surveys/:id/update_background_image
    # surveys_background_image_path(:id)
    # surveys_background_image_url(:id)
    def update_background_image
      if params.permit(:image_delete).dig(:image_delete).to_bool
        @survey.background_image.purge if @survey.background_image.attached?
      else
        @survey.update(background_image: params.require(:survey).permit(:background_image).dig(:background_image))
      end

      render partial: 'surveys/js/show', locals: { cards: %w[survey_edit] }
    end

    # (PATCH)
    # /surveys/:id/update_logo_image
    # surveys_logo_image_path(:id)
    # surveys_logo_image_url(:id)
    def update_logo_image
      if params.permit(:image_delete).dig(:image_delete).to_bool
        @survey.logo_image.purge if @survey.logo_image.attached?
      else
        @survey.update(logo_image: params.require(:survey).permit(:logo_image).dig(:logo_image))
      end

      render partial: 'surveys/js/show', locals: { cards: %w[survey_edit] }
    end

    private

    def authorize_user!
      super
      return if current_user.access_controller?('surveys', 'allowed', session)

      raise ExceptionHandlers::UserNotAuthorized.new('Survey Builder', root_path)
    end

    def general_form_fields
      ::Webhook.internal_key_hash(@survey.client, 'contact', %w[personal ext_references]).keys.map(&:to_sym) + %i[notes user_id sleep block ok2text ok2email]
    end

    def params_client_custom_fields
      params.include?(:client_custom_fields) ? params.require(:client_custom_fields).permit(params[:client_custom_fields].keys.map(&:to_sym) - general_form_fields - ::Webhook.internal_key_hash(@survey.client, 'contact', %w[phones]).keys.map(&:to_sym)) : {}
    end

    def params_contact
      if params.include?(:client_custom_fields)
        sanitized_params = params.require(:client_custom_fields).permit(general_form_fields)

        if sanitized_params.dig(:fullname).to_s.present?
          fullname = sanitized_params[:fullname].to_s.parse_name
          sanitized_params[:firstname] = fullname[:firstname] if sanitized_params.dig(:firstname).to_s.blank?
          sanitized_params[:lastname]  = fullname[:lastname] if sanitized_params.dig(:lastname).to_s.blank?
        end

        sanitized_params.delete(:fullname)
      else
        sanitized_params = {}
      end

      sanitized_params
    end

    def params_contact_phone
      if params.include?(:client_custom_fields)
        params.require(:client_custom_fields).permit(::Webhook.internal_key_hash(@survey.client, 'contact', %w[phones]).symbolize_keys.keys).to_h.to_h { |k, v| [v.clean_phone(@survey.client.primary_area_code), k.gsub('phone_', '')] }
      else
        {}
      end
    end

    def params_include_page_name?
      params.include?(:page_name)
    end

    def params_show
      sanitized_params = params.permit(:cid, :rid)
      @cid = sanitized_params.dig(:cid).to_i
      @rid = sanitized_params.dig(:rid).to_i
    end

    def params_survey
      sanitized_params = params.require(:surveys_survey).permit(:background_color, :facebook_pixel_base_code, :header_color, :first_screen_id, :name, :page_domain, :page_name, footer_links: %i[label_01 link_01 label_02 link_02 label_03 link_03])

      sanitized_params[:facebook_pixel_base_code] = sanitized_params.dig(:facebook_pixel_base_code)&.gsub('{script', '<script')&.gsub('{/script}', '</script>')&.gsub('{noscript', '<noscript')&.gsub('{/noscript}', '</noscript>').to_s
      sanitized_params[:first_screen_id] = sanitized_params.dig(:first_screen_id).to_i

      sanitized_params
    end

    # save User selection from Survey question to selected Custom Field
    def save_selection
      sanitized_params = params.permit(:sel, :ssid)

      return unless (@rid.positive? && (survey_result = ::Surveys::Result.find_by(id: @rid, survey_id: @survey.id))) ||
                    (@cid.positive? && (survey_result = ::Surveys::Result.find_or_create_by(survey_id: @survey.id, contact_id: @cid))) ||
                    (survey_result = ::Surveys::Result.new)

      if sanitized_params.dig(:ssid).present? && ::Surveys::Screen.find_by(id: sanitized_params[:ssid], survey_id: @survey.id).present?
        survey_result.survey_id = @survey.id
        survey_result.contact_id = @cid unless @cid.zero?
        survey_result.screen_results[sanitized_params[:ssid].to_s] = sanitized_params.dig(:sel).to_s
        survey_result.save
      end

      @rid = survey_result.id unless survey_result.new_record?
      contact = Contact.find_by(id: @cid, client_id: @survey.client_id)

      Integrations::Searchlight::V1::PostSurveyJob.perform_later(
        action_at:        Time.current,
        client_id:        @survey.client_id,
        contact_id:       contact&.id,
        survey_id:        @survey.id,
        survey_result_id: survey_result.id,
        survey_screen_id: @survey_screen.id,
        user_id:          contact&.user_id
      )

      return unless @cid.positive? && contact

      custom_fields = {}

      ::Surveys::Screen.where(id: survey_result.screen_results.keys).find_each do |survey_screen|
        custom_fields[survey_screen.custom_field_id] = survey_result.screen_results[survey_screen.id.to_s] if survey_screen.custom_field_id.positive? && survey_result.screen_results.dig(survey_screen.id.to_s).present?
      end

      contact.update_custom_fields(custom_fields:)
    end

    def survey
      survey_id = params.dig(:id).to_i

      return if survey_id.positive? && (@survey = current_user.client.surveys.find_by(id: survey_id))

      sweetalert_error('Unathorized Access!', 'Your account could NOT be confirmed.', '', { persistent: 'OK' })

      respond_to do |format|
        format.js   { render js: "window.location = '#{root_path}'" and return false }
        format.html { redirect_to root_path and return false }
      end
    end

    def survey_by_key
      return if params.dig(:survey_key).to_s.present? && (@survey = ::Surveys::Survey.find_by(survey_key: params[:survey_key].to_s))

      sweetalert_error('We\'re Sorry!', 'We were unable to locate the requested survey.', '', { persistent: 'OK' })

      respond_to do |format|
        format.js   { render js: "window.location = '#{root_path}'" and return false }
        format.html { redirect_to root_path and return false }
      end
    end

    def survey_by_page_name
      page_name = params.dig(:page_name)

      return if page_name.present? && (@survey = ::Surveys::Survey.where('data @> ?', { page_domain: request.domain }.to_json).find_by('data @> ?', { page_name: }.to_json)) && (@survey_screen = @survey.screens.find_by(id: @survey.first_screen_id) || @survey.screens.first)

      sweetalert_error('We\'re Sorry!', 'We were unable to locate the requested survey.', '', { persistent: 'OK' })

      respond_to do |format|
        format.js   { render js: "window.location = '#{root_path}'" and return false }
        format.html { redirect_to root_path and return false }
      end
    end

    def survey_screen_by_key
      return if params.dig(:screen_key).to_s.present? && (@survey_screen = params[:screen_key].to_s == '0' ? @survey.screens.find_by(id: @survey.first_screen_id) || @survey.screens.first : @survey.screens.find_by(screen_key: params[:screen_key].to_s))

      sweetalert_error('We\'re Sorry!', 'We were unable to locate the requested screen.', '', { persistent: 'OK' })

      respond_to do |format|
        format.js   { render js: "window.location = '#{root_path}'" and return false }
        format.html { redirect_to root_path and return false }
      end
    end

    def user_api_integration_for_activeprospect
      @user_api_integration = UserApiIntegration.find_by(user_id: @survey.client.def_user_id, target: 'activeprospect')
    end
  end
end
