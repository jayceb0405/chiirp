# frozen_string_literal: true

# app/controllers/tags_controller.rb
class TagsController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_user!, only: %i[create destroy update]
  before_action :tag, only: %i[destroy edit update]

  # (POST)
  # /tags
  # tags_path(:contact_id)
  # tags_url(:contact_id)
  def create
    @tag = current_user.client.tags.find_or_create_by(name: tag_params.dig(:name))
    tag_statistics

    if select_or_add_field_name == 'tag_id' && select_or_add_div_id == 'client_tag'
      @tag = current_user.client.tags.new
      render partial: 'tags/js/show', locals: {
        cards:                    [1, 2],
        select_or_add_field_name:,
        select_or_add_div_id:,
        exclude_tags:,
        autofocus:
      }
    else
      @tag = current_user.client.tags.new unless select_or_add_field_name.present? || select_or_add_div_id.present?
      render partial: 'tags/js/show', locals: {
        cards:                    [3],
        select_or_add_field_name:,
        select_or_add_div_id:,
        exclude_tags:,
        autofocus:
      }
    end
  end

  # (DELETE) delete a Tag
  # /tags/:id
  # tag_path(:id)
  # tag_url(:id)
  def destroy
    @tag.destroy

    @tag = current_user.client.tags.new
    tag_statistics

    render partial: 'tags/js/show', locals: {
      cards:                    [1],
      select_or_add_field_name:,
      select_or_add_div_id:,
      exclude_tags:,
      autofocus:
    }
  end

  # (GET) edit a Tag
  # /tags/:id/edit
  # edit_tag_path(:id)
  # edit_tag_url(:id)
  def edit
    render partial: 'tags/js/show', locals: {
      cards:                    [2],
      select_or_add_field_name:,
      select_or_add_div_id:,
      exclude_tags:,
      autofocus:,
      allow_cgt_assignments:    true
    }
  end

  # (GET) edit a new Tag
  # /tags/new
  # new_tag_path
  # new_tag_url
  def new
    @tag = current_user.client.tags.new

    render partial: 'tags/js/show', locals: {
      cards:                    [2],
      select_or_add_field_name:,
      select_or_add_div_id:,
      exclude_tags:,
      disabled:,
      autofocus:
    }
  end

  # (PUT/PATCH) update a Tag
  # /tags/:id
  # tag_path(:id)
  # tag_url(:id)
  def update
    @tag.update(tag_params)

    @tag = current_user.client.tags.new
    tag_statistics

    render partial: 'tags/js/show', locals: {
      cards:                    [1, 2],
      select_or_add_field_name:,
      select_or_add_div_id:,
      exclude_tags:,
      autofocus:
    }
  end

  private

  def authorize_user!
    super
    return if current_user.access_controller?('clients', 'tags', session)

    raise ExceptionHandlers::UserNotAuthorized.new('Tags', root_path)
  end

  def autofocus
    params.dig(:autofocus).to_bool
  end

  def disabled
    params.dig(:disabled).to_bool
  end

  def exclude_tags
    params.dig(:exclude_tags).is_a?(Array) ? params.dig(:exclude_tags) : []
  end

  def select_or_add_div_id
    (params.dig(:select_or_add_div_id) || 'client_tag').to_s
  end

  def select_or_add_field_name
    (params.dig(:select_or_add_field_name) || 'tag_id').to_s
  end

  def tag_statistics
    @tags                   = current_user.client.tags.select('tags.id, tags.name, tags.color, count(contacts.id) AS contact_count').left_outer_joins(:contacts).group(:id).order(:name)
    @client_widget_tags     = current_user.client.client_widgets.where('tag_id > 0').pluck(:tag_id).compact
    @user_contact_form_tags = UserContactForm.where(user_id: current_user.client.users.pluck(:id)).where('tag_id > 0').pluck(:tag_id).compact
    @trackable_link_tags    = current_user.client.trackable_links.where('tag_id > 0').pluck(:tag_id).compact
    @triggeraction_tags     = []

    Triggeraction.for_client_and_action_type(current_user.client_id, [300, 305]).find_each do |triggeraction|
      @triggeraction_tags << triggeraction.tag_id if triggeraction.tag_id.positive?
    end

    Triggeraction.for_client_and_action_type(current_user.client_id, [605]).find_each do |triggeraction|
      triggeraction.response_range.each_value do |values|
        @triggeraction_tags << values['tag_id'] if values.dig('tag_id').to_i.positive?
      end
    end

    @triggeraction_tags.compact
  end

  def tag
    if defined?(current_user) && params.include?(:id)
      return if (@tag = current_user.client.tags.find_by(id: params[:id]))

      # Tag was NOT found
      sweetalert_error('Unknown Tag!', 'The Tag you requested could not be found.', '', { persistent: 'OK' })
    else
      # only logged in Users may access any Tag actions
      sweetalert_error('Unknown Tag!', 'A Tag was NOT requested.', '', { persistent: 'OK' })
    end

    render js: "window.location = '#{root_path}'" and return false
  end

  def tag_params
    sanitized_params = params.require(:tag).permit(:name, :campaign_id, :group_id, :stage_id, :tag_id, :color)

    sanitized_params[:campaign_id] = sanitized_params.dig(:campaign_id).to_i
    sanitized_params[:group_id]    = sanitized_params.dig(:group_id).to_i
    sanitized_params[:stage_id]    = sanitized_params.dig(:stage_id).to_i
    sanitized_params[:tag_id]      = sanitized_params.dig(:tag_id).to_i

    sanitized_params
  end
end
