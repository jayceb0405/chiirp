# frozen_string_literal: true

# app/controllers/concerns/authorizable.rb
module Authorizable
  extend ActiveSupport::Concern

  def authorize_client!(client)
    client.active?
  end

  def authorize_user!
    # Rails.logger.info "controller_name: #{controller_name.inspect} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"
    # Rails.logger.info "action_name: #{action_name.inspect} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"
    # Rails.logger.info "self.class: #{self.class.inspect} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"
    # Rails.logger.info "self.class.to_s.split('::'): #{self.class.to_s.split('::').inspect} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"
    if current_user
      split_class = self.class.to_s.split('::')

      if split_class[0] != 'SystemSettings' && controller_name == 'integrations' && split_class.length > 1 &&
         current_user.client.integrations_allowed.exclude?(split_class[1].underscore) &&
         current_user.client.integrations_allowed.exclude?("#{split_class[1].underscore}_#{split_class[2].underscore}") &&
         current_user.client.integrations_allowed.exclude?("#{split_class[1].underscore}_leads") &&
         current_user.client.integrations_allowed.exclude?("#{split_class[1].underscore}_messenger") &&
         current_user.client.integrations_allowed.exclude?("#{split_class[1].underscore}_marketing")

        raise ExceptionHandlers::UserNotAuthorized.new('the requested integration', root_path)
      end
    else
      Rails.logger.info "Authorizable#authorize_user!: #{{ class: self.class.to_s.split('::'), message: 'Current_user is nil' }.inspect} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"
      raise ExceptionHandlers::UserNotAuthorized.new('', login_path)
    end

    true
  end
end
