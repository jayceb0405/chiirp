# frozen_string_literal: true

class ShortCodesController < ApplicationController
  def show
    short_code = ShortCode.find_by!(code: params[:code])

    redirect_to short_code.url, allow_other_host: true, status: :found
  rescue ActiveRecord::RecordNotFound
    render plain: 'Not Found', status: :not_found
  end
end
