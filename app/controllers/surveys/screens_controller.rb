# frozen_string_literal: true

# app/controllers/surveys/screens_controller.rb
module Surveys
  class ScreensController < Surveys::SurveysController
    before_action :authenticate_user!
    before_action :survey
    before_action :authorize_user!
    before_action :survey_screen, only: %i[destroy edit update update_image]

    # (DELETE) destroy a Survey Screen
    # /surveys/surveys/:survey_id/surveys_screens/:id
    # surveys_survey_surveys_screen_path(:survey_id, :id)
    # surveys_survey_surveys_screen_url(:survey_id, :id)
    def destroy
      @survey_screen.destroy

      render partial: 'surveys/js/show', locals: { cards: %w[survey_screens_index first_screen_id_edit] }
    end

    # (GET) display a Survey Screen to edit
    # /surveys/surveys/:survey_id/surveys_screens/:id/edit
    # edit_surveys_survey_surveys_screen_path(:survey_id, :id)
    # edit_surveys_survey_surveys_screen_url(:survey_id, :id)
    def edit
      render partial: 'surveys/js/show', locals: { cards: %w[survey_screen_edit] }
    end

    # (GET) list all Survey Screen
    # /surveys/surveys/:survey_id/surveys_screens
    # surveys_survey_surveys_screens_path(:survey_id)
    # surveys_survey_surveys_screens_url(:survey_id)
    def index
      render partial: 'surveys/js/show', locals: { cards: %w[survey_screens_index] }
    end

    # (GET) initialize a new Survey Screen
    # /surveys/surveys/:survey_id/surveys_screens/new
    # new_surveys_survey_surveys_screen_path(:survey_id)
    # new_surveys_survey_surveys_screen_url(:survey_id)
    def new
      @survey_screen = @survey.screens.create(name: "New #{::Surveys::Screen.title}", screen_type: 'question')

      render partial: 'surveys/js/show', locals: { cards: %w[survey_screens_index survey_screen_open_new] }
    end

    # (PATCH/PUT) update a Survey Screen
    # /surveys/surveys/:survey_id/surveys_screens/:id
    # surveys_survey_surveys_screen_path(:survey_id, :id)
    # surveys_survey_surveys_screen_url(:survey_id, :id)
    def update
      @survey_screen.update(params_screen)

      render partial: 'surveys/js/show', locals: { cards: %w[survey_screen_edit td_screen_name first_screen_id_edit] }
    end

    # (PATCH)
    # /surveys/:survey_id/screens/:id/update_image/:question_id
    # surveys_screen_image_path(:survey_id, :id, :question_id)
    # surveys_screen_image_url(:survey_id, :id, :question_id)
    def update_image
      image_delete = params.dig(:image_delete).to_bool

      if image_delete
        @survey_screen.send(:"question_#{params[:question_id]}_image").purge
      else
        question_image = params.require(:surveys_screen).permit(responses: [option_0: [:image], option_1: [:image], option_2: [:image], option_3: [:image], option_4: [:image]]).dig(:responses, :"option_#{params[:question_id]}", :image)
        @survey_screen.update("question_#{params[:question_id]}_image": question_image)
      end

      render partial: 'surveys/js/show', locals: { cards: %w[tr_survey_screen_option], option_id: params[:question_id] }
    end

    private

    def params_data
      form_fields      = [::Webhook.internal_key_hash(@survey.client, 'contact', %w[personal phones custom_fields]).to_h { |k, _v| [k, %w[order show required]] }]
      sanitized_params = params.require(:surveys_screen).permit(form_data: %i[question submit_button_text ok2text ok2text_text ok2email ok2email_text submit_button_color disclaimer_text], actions: %i[campaign_id group_id tag_id stage_id redirect_screen_id redirect_url] + [{ stop_campaign_ids: [] }], form_fields:)

      sanitized_params[:actions]                      = sanitized_params.dig(:actions) || {}
      sanitized_params[:actions][:campaign_id]        = sanitized_params.dig(:actions, :campaign_id).to_i
      sanitized_params[:actions][:group_id]           = sanitized_params.dig(:actions, :group_id).to_i
      sanitized_params[:actions][:tag_id]             = sanitized_params.dig(:actions, :tag_id).to_i
      sanitized_params[:actions][:stage_id]           = sanitized_params.dig(:actions, :stage_id).to_i
      sanitized_params[:actions][:stop_campaign_ids]  = sanitized_params.dig(:actions, :stop_campaign_ids)&.compact_blank
      sanitized_params[:actions][:stop_campaign_ids]  = [0] if sanitized_params.dig(:actions, :stop_campaign_ids)&.include?('0')
      sanitized_params[:actions][:redirect_screen_id] = sanitized_params.dig(:actions, :redirect_screen_id).to_i

      sanitized_params
    end

    def params_info
      sanitized_params = params.require(:surveys_screen).permit(info: [:question, :info, { actions: %i[redirect_screen_id redirect_url] }]).dig(:info) || {}

      sanitized_params[:actions][:redirect_screen_id] = sanitized_params.dig(:actions, :redirect_screen_id).to_i

      sanitized_params
    end

    def params_question
      sanitized_params = params.require(:surveys_screen).permit(:question, :custom_field_id, responses: [option_0: %i[string screen url], option_1: %i[string screen url], option_2: %i[string screen url], option_3: %i[string screen url], option_4: %i[string screen url]]) || {}

      sanitized_params[:custom_field_id] = sanitized_params.dig(:custom_field_id).to_i
      sanitized_params.dig(:responses).each { |k, v| sanitized_params[:responses][k][:screen] = v.dig(:screen).to_i }

      sanitized_params
    end

    def params_screen
      sanitized_params = params.require(:surveys_screen).permit(:name, :header, :sub_header, :screen_type, :facebook_event_code)

      sanitized_params[:facebook_event_code] = sanitized_params.dig(:facebook_event_code).to_s.gsub('{script', '<script').gsub('{/script}', '</script>').gsub('{noscript', '<noscript').gsub('{/noscript}', '</noscript>')

      sanitized_params.merge!(send("params_#{sanitized_params.dig(:screen_type)}"))
    end

    def survey_screen
      screen_id = params.dig(:id).to_i

      return if screen_id.positive? && (@survey_screen = @survey.screens.find_by(id: screen_id))

      sweetalert_error('Unathorized Access!', 'Your account could NOT be confirmed.', '', { persistent: 'OK' })

      respond_to do |format|
        format.js   { render js: "window.location = '#{root_path}'" and return false }
        format.html { redirect_to root_path and return false }
      end
    end

    def survey
      survey_id = params.permit(:survey_id).dig(:survey_id).to_i

      return if survey_id.positive? && (@survey = current_user.client.surveys.find_by(id: survey_id))

      sweetalert_error('Unathorized Access!', 'Your account could NOT be confirmed.', '', { persistent: 'OK' })

      respond_to do |format|
        format.js   { render js: "window.location = '#{root_path}'" and return false }
        format.html { redirect_to root_path and return false }
      end
    end
  end
end
