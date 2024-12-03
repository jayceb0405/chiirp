# frozen_string_literal: true

FactoryBot.define do
  factory :trigger do
    campaign
    trigger_type { 115 }
    step_numb { 1 }
  end
end
