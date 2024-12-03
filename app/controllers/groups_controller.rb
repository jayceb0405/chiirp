# frozen_string_literal: true

# app/controllers/groups_controller.rb
class GroupsController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_user!
  before_action :params_common

  # (POST) create a new Group
  # /groups
  # groups_path
  # groups_url
  def create
    @group = current_user.client.groups.find_or_create_by(params_group)
  end

  # (GET) edit a new Group
  # /groups/new
  # new_group_path
  # new_group_url
  def new
    @group = current_user.client.groups.new
  end

  private

  def authorize_user!
    super
    return if current_user.access_controller?('clients', 'groups', session)

    raise ExceptionHandlers::UserNotAuthorized.new('Groups', root_path)
  end

  def params_common
    sanitized_params = params.permit(:autofocus, :disabled, :exclude_groups, :select_or_add_div_id, :select_or_add_field_name)

    @autofocus                = sanitized_params.dig(:autofocus).to_bool
    @disabled                 = sanitized_params.dig(:disabled).to_bool
    @exclude_groups           = sanitized_params.dig(:exclude_groups).is_a?(Array) ? sanitized_params.dig(:exclude_groups) : []
    @select_or_add_div_id     = (sanitized_params.dig(:select_or_add_div_id) || 'client_group').to_s
    @select_or_add_field_name = (sanitized_params.dig(:select_or_add_field_name) || 'group_id').to_s
  end

  def params_group
    params.require(:group).permit(:name)
  end
end
