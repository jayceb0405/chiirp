# frozen_string_literal: true

# app/models/contacts/search.rb
module Contacts
  class Search
    # sanitized search params
    # Contacts::Search.new.sanitize_params()
    #   (req) params:        (ActionController::Parameters)
    #   (req) user:          (User)
    #   (opt) user_settings: (Users::Setting)
    def sanitize_params(**args)
      return {} unless args.dig(:user).is_a?(User)

      sanitized_params = if args.dig(:params, :data).present?
                           args[:params].require(:data).permit(
                             :all_tags,
                             :block,
                             :campaign_id,
                             :campaign_id_completed,
                             :campaign_id_created_at_dynamic,
                             :campaign_id_created_at_from,
                             :campaign_id_created_at_to,
                             :contacttag_created_at_dynamic,
                             :contacttag_created_at_from,
                             :contacttag_created_at_to,
                             :created_at_dynamic,
                             :created_at_from,
                             :created_at_to,
                             :custom_fields_updated_at,
                             :custom_fields_updated_at_dynamic,
                             :custom_fields_updated_at_from,
                             :custom_fields_updated_at_to,
                             :has_number,
                             :group_id,
                             :group_id_updated_dynamic,
                             :group_id_updated_from,
                             :group_id_updated_to,
                             :lead_source_id,
                             :lead_source_id_updated_dynamic,
                             :lead_source_id_updated_from,
                             :lead_source_id_updated_to,
                             :last_msg_absolute,
                             :last_msg_dynamic,
                             :last_msg_direction,
                             :last_msg_from,
                             :last_msg_to,
                             :last_msg_string,
                             :not_has_number,
                             :ok2email,
                             :ok2text,
                             :per_page,
                             :search_string,
                             :since_last_contact,
                             :sleep,
                             :stage_id,
                             :stage_id_updated_dynamic,
                             :stage_id_updated_from,
                             :stage_id_updated_to,
                             :trackable_link_id,
                             :trackable_link_clicked,
                             :trackable_link_id_created_at_dynamic,
                             :trackable_link_id_created_at_from,
                             :trackable_link_id_created_at_to,
                             :updated_at_dynamic,
                             :updated_at_from,
                             :updated_at_to,
                             custom_fields: {},
                             show_user_ids: [],
                             sort:          %i[col dir],
                             tags_exclude:  [],
                             tags_include:  []
                           )
                         else
                           {}
                         end

      sanitized_params = (args.dig(:user_settings) || args[:user].user_settings.new(controller_action: 'contacts_search')).data.merge(sanitized_params.to_h.deep_symbolize_keys)

      # strip null character from search string
      sanitized_params[:search_string] = sanitized_params.dig(:search_string).to_s.clean_smart_quotes
      sanitized_params[:show_user_ids] = [sanitized_params.dig(:show_user_ids) || args[:user].id].flatten.compact_blank.uniq
      sanitized_params[:tags_include]  = [sanitized_params.dig(:tags_include) || []].flatten.reject(&:empty?)
      sanitized_params[:tags_exclude]  = [sanitized_params.dig(:tags_exclude) || []].flatten.reject(&:empty?)

      # convert strings to numbers
      sanitized_params[:campaign_id]        = sanitized_params.dig(:campaign_id).to_i
      sanitized_params[:group_id]           = sanitized_params.dig(:group_id).to_i
      sanitized_params[:lead_source_id]     = sanitized_params.dig(:lead_source_id).to_i
      sanitized_params[:stage_id]           = sanitized_params.dig(:stage_id).to_i
      sanitized_params[:since_last_contact] = sanitized_params.dig(:since_last_contact).to_i
      sanitized_params[:trackable_link_id]  = sanitized_params.dig(:trackable_link_id).to_i

      # convert strings/integers to boolean
      sanitized_params[:trackable_link_clicked] = sanitized_params.dig(:trackable_link_clicked).to_bool

      # convert dynamic date to 2 dates
      %w[created_at updated_at last_msg group_id_updated contacttag_created_at trackable_link_id_created_at].each do |period_type|
        if sanitized_params.dig(period_type.to_sym).to_s.present?
          custom_dates = sanitized_params.dig(period_type.to_sym).to_s.split(' to ')

          sanitized_params[:"#{period_type}_dynamic"] = ''

          if custom_dates.length == 2
            sanitized_params[:"#{period_type}_from"]    = custom_dates[0].to_s
            sanitized_params[:"#{period_type}_to"]      = custom_dates[1].to_s
          else
            sanitized_params[:"#{period_type}_from"]    = ''
            sanitized_params[:"#{period_type}_to"]      = ''
          end
        end

        sanitized_params.delete(period_type.to_sym)
      end

      if sanitized_params.dig(:last_msg_string).present? && (sanitized_params.dig(:last_msg_dynamic).blank? & sanitized_params.dig(:last_msg).blank?)
        # request to search text message for a string provided without a valid date range > set to Last 7 Days
        sanitized_params[:last_msg_dynamic] = 'l7'
      end

      # only save ClientCustomFields that were used
      custom_fields = []

      if sanitized_params.dig(:custom_fields).is_a?(Hash)

        sanitized_params[:custom_fields].each_value do |custom_field|
          if custom_field.dig(:operator).to_s.present? && custom_field.dig(:value).to_s.present?
            custom_fields << {
              id:       custom_field[:id].to_i,
              operator: custom_field[:operator].to_s,
              value:    custom_field[:value].to_s
            }
          end
        end
      end

      sanitized_params[:custom_fields] = custom_fields

      sanitized_params[:sort] = {} unless sanitized_params.dig(:sort).is_a?(Hash)
      # support for legacy
      sort = args[:params].permit(sort: %i[col dir])
      sanitized_params[:sort][:col] = sort.dig(:sort, :col).to_s unless sort.dig(:sort, :col).nil?
      sanitized_params[:sort][:dir] = sort.dig(:sort, :dir).to_s unless sort.dig(:sort, :dir).nil?
      sanitized_params[:per_page]   = [(args[:params].permit(:per_page).dig(:per_page) || sanitized_params.dig(:per_page) || 25).to_i, 200].min
      # support for new ui
      sanitized_params[:all_tags]   = sanitized_params.dig(:all_tags).to_bool ? '1' : '0'
      sanitized_params[:ok2email]   = if %w[2 all].include?(sanitized_params.dig(:ok2email).to_s.downcase)
                                        '2'
                                      else
                                        sanitized_params.dig(:ok2email).to_bool ? '1' : '0'
                                      end
      sanitized_params[:ok2text]    = if %w[2 all].include?(sanitized_params.dig(:ok2text).to_s.downcase)
                                        '2'
                                      else
                                        sanitized_params.dig(:ok2text).to_bool ? '1' : '0'
                                      end
      sort = args[:params].permit(:order_column, :order_direction)
      sanitized_params[:sort][:col] = sort[:order_column] unless sort.dig(:order_column).nil?
      sanitized_params[:sort][:dir] = sort[:order_direction].to_s unless sort.dig(:order_direction).nil?
      sanitized_params[:per_page]   = [(args[:params].permit(:page_size).dig(:page_size) || sanitized_params.dig(:per_page) || 25).to_i, 200].min

      if args.dig(:params, :data).present?
        tag_created_at = args[:params].require(:data).permit(:tag_created_at_dynamic, :tag_created_at_from, :tag_created_at_to)
        sanitized_params[:contacttag_created_at_dynamic] = tag_created_at[:tag_created_at_dynamic] unless tag_created_at.dig(:tag_created_at_dynamic).nil?
        sanitized_params[:contacttag_created_at_from]    = tag_created_at[:tag_created_at_from] unless tag_created_at.dig(:tag_created_at_from).nil?
        sanitized_params[:contacttag_created_at_to]      = tag_created_at[:tag_created_at_to] unless tag_created_at.dig(:tag_created_at_to).nil?
      end

      sanitized_params
    end

    # initialize a new "contacts_search" object with attributes specific to a configured dashboard button
    # Contacts::Search.new.configure_user_settings_data_from_dashboard_button()
    #   (req) params:                            (ActionController::Parameters)
    #   (req) user:                              (User)
    #   (req) user_settings_dashboard_button_id: (Integer)
    def configure_user_settings_data_from_dashboard_button(args = {})
      return {} unless args.dig(:user).is_a?(User)

      user_settings_data = args[:user].user_settings.new(controller_action: 'contacts_search').data

      return user_settings_data unless args.dig(:params).is_a?(ActionController::Parameters) && args.dig(:user_settings_dashboard_button_id).to_i.positive? &&
                                       (user_settings_dashboard_button = args[:user].user_settings.find_by(id: args[:user_settings_dashboard_button_id].to_i))

      user_settings_data[:created_at_dynamic] = user_settings_dashboard_button.data.dig(:dynamic).to_s
      user_settings_data[:created_at_from]    = user_settings_dashboard_button.data.dig(:from).to_s
      user_settings_data[:created_at_to]      = user_settings_dashboard_button.data.dig(:to).to_s
      user_settings_data[:show_user_ids]      = args.dig(:params, :leads).to_s.casecmp?('client') ? ["all_#{args[:user].client_id}"] : [(user_settings_dashboard_button.data.dig(:buttons_user_id) || args[:user].id).to_i]

      if args.dig(:params, :last_msg_direction).to_s.present?
        # Text Messages button was clicked (Sent or Rcvd)
        user_settings_data[:created_at_dynamic]                   = ''
        user_settings_data[:created_at_from]                      = ''
        user_settings_data[:created_at_to]                        = ''
        user_settings_data[:last_msg_string]                      = ''
        user_settings_data[:last_msg_dynamic]                     = user_settings_dashboard_button.data.dig(:dynamic).to_s
        user_settings_data[:last_msg_direction]                   = args.dig(:params, :last_msg_direction).to_s.downcase
        user_settings_data[:last_msg_absolute]                    = args.dig(:params, :last_msg_absolute).to_s.downcase
        user_settings_data[:last_msg_from]                        = user_settings_dashboard_button.data.dig(:from).to_s
        user_settings_data[:last_msg_to]                          = user_settings_dashboard_button.data.dig(:to).to_s
      elsif args.dig(:params, :group_id).to_i.positive?
        # Groups button was clicked
        user_settings_data[:created_at_dynamic]                   = ''
        user_settings_data[:created_at_from]                      = ''
        user_settings_data[:created_at_to]                        = ''
        user_settings_data[:group_id]                             = args.dig(:params, :group_id).to_s
        user_settings_data[:group_id_updated_dynamic]             = user_settings_dashboard_button.data.dig(:dynamic).to_s
        user_settings_data[:group_id_updated_from]                = user_settings_dashboard_button.data.dig(:from).to_s
        user_settings_data[:group_id_updated_to]                  = user_settings_dashboard_button.data.dig(:to).to_s
      elsif args.dig(:params, :lead_source_id).to_i.positive?
        # Lead Sources button was clicked
        user_settings_data[:created_at_dynamic]                   = ''
        user_settings_data[:created_at_from]                      = ''
        user_settings_data[:created_at_to]                        = ''
        user_settings_data[:lead_source_id]                       = args.dig(:params, :lead_source_id).to_s
        user_settings_data[:lead_source_id_updated_dynamic]       = user_settings_dashboard_button.data.dig(:dynamic).to_s
        user_settings_data[:lead_source_id_updated_from]          = user_settings_dashboard_button.data.dig(:from).to_s
        user_settings_data[:lead_source_id_updated_to]            = user_settings_dashboard_button.data.dig(:to).to_s
      elsif args.dig(:params, :stage_id).to_i.positive?
        # Lead Sources button was clicked
        user_settings_data[:created_at_dynamic]                   = ''
        user_settings_data[:created_at_from]                      = ''
        user_settings_data[:created_at_to]                        = ''
        user_settings_data[:stage_id]                             = args.dig(:params, :stage_id).to_s
        user_settings_data[:stage_id_updated_dynamic]             = user_settings_dashboard_button.data.dig(:dynamic).to_s
        user_settings_data[:stage_id_updated_from]                = user_settings_dashboard_button.data.dig(:from).to_s
        user_settings_data[:stage_id_updated_to]                  = user_settings_dashboard_button.data.dig(:to).to_s
      elsif args.dig(:params, :tag_id).to_i.positive?
        # Tags button was clicked
        user_settings_data[:created_at_dynamic]                   = ''
        user_settings_data[:created_at_from]                      = ''
        user_settings_data[:created_at_to]                        = ''
        user_settings_data[:tags_include]                         = [args.dig(:params, :tag_id).to_s]
        user_settings_data[:contacttag_created_at_dynamic]        = user_settings_dashboard_button.data.dig(:dynamic).to_s
        user_settings_data[:contacttag_created_at_from]           = user_settings_dashboard_button.data.dig(:from).to_s
        user_settings_data[:contacttag_created_at_to]             = user_settings_dashboard_button.data.dig(:to).to_s
      elsif %w[active completed].include?(args.dig(:params, :campaign_id_completed).to_s.downcase)
        # Campaigns button was clicked
        user_settings_data[:created_at_dynamic]                   = ''
        user_settings_data[:created_at_from]                      = ''
        user_settings_data[:created_at_to]                        = ''
        user_settings_data[:campaign_id]                          = args.dig(:params, :campaign_id).to_s
        user_settings_data[:campaign_id_completed]                = args.dig(:params, :campaign_id_completed).to_s.downcase
        user_settings_data[:campaign_id_created_at_dynamic]       = user_settings_dashboard_button.data.dig(:dynamic).to_s
        user_settings_data[:campaign_id_created_at_from]          = user_settings_dashboard_button.data.dig(:from).to_s
        user_settings_data[:campaign_id_created_at_to]            = user_settings_dashboard_button.data.dig(:to).to_s
      elsif args.dig(:params, :trackable_link_id).to_i.positive?
        # Trackable Links button was clicked
        user_settings_data[:created_at_dynamic]                   = ''
        user_settings_data[:created_at_from]                      = ''
        user_settings_data[:created_at_to]                        = ''
        user_settings_data[:trackable_link_id]                    = args.dig(:params, :trackable_link_id).to_s
        user_settings_data[:trackable_link_clicked]               = false
        user_settings_data[:trackable_link_id_created_at_dynamic] = user_settings_dashboard_button.data.dig(:dynamic).to_s
        user_settings_data[:trackable_link_id_created_at_from]    = user_settings_dashboard_button.data.dig(:from).to_s
        user_settings_data[:trackable_link_id_created_at_to]      = user_settings_dashboard_button.data.dig(:to).to_s
      end

      user_settings_data
    end
  end
end
