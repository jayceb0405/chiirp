# frozen_string_literal: true

module Testing
  class FormatsController < ApplicationController
    before_action :authenticate_user!
    before_action :authorize_user!

    # (GET)
    # /LjR8XqKTIec4M1Bw/Q6gF8HkrlDYvDp5p
    def show
      session[:sign_in_at] = 1
    end

    # (GET)
    # /LjR8XqKTIec4M1Bw/Q6gF8HkrlDYvDp5p/test
    def test
      respond_to do |format|
        format.html
        format.js
        format.turbo_stream
      end
    end
  end
end
