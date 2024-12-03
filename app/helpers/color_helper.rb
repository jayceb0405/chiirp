# frozen_string_literal: true

# app/helpers/color_helper.rb
module ColorHelper
  def bubble_color
    %w[bg-red bg-orange bg-blue bg-indigo bg-teal bg-purple bg-pink bg-yellow bg-cyan bg-green][rand(10)]
  end
end
