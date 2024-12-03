# frozen_string_literal: true

# app/lib/exception_handlers/user_not_authorized.rb
module ExceptionHandlers
  class UserNotAuthorized < StandardError
    attr_accessor :redirect_url

    def initialize(message, redirect_url)
      super(message)

      @redirect_url = redirect_url
    end
  end
end
