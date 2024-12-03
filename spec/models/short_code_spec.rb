# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ShortCode, type: :model do
  let(:client) { create :client }

  it 'creates a code before saving' do
    short_code = ShortCode.new(url: 'https://www.apple.com', client:)
    expect(short_code.save).to be true
  end
end
