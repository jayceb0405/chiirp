# frozen_string_literal: true

# app/controllers/api/ui/v1/users_controller.rb
module Api
  module Ui
    module V1
      class MiscController < Api::Ui::V1::BaseController
        # (GET) provide JSON data for a collection of timeframes
        # /api/ui/v1/misc/timeframes
        # timeframes_api_ui_v1_misc_index_path
        # timeframes_api_ui_v1_misc_index_url
        def timeframes
          render json: Users::Dashboards::Dashboard::DYNAMIC_DATES_ARRAY
        end
      end
    end
  end
end
