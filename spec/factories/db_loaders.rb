# frozen_string_literal: true

FactoryBot.define do
  factory :db_loader do
    key { 'MyString' }
    last_start_at { '2024-03-21 07:25:08' }
    last_stop_at { '2024-03-21 07:25:08' }
  end
end
