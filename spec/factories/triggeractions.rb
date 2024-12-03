# frozen_string_literal: true

FactoryBot.define do
  factory :triggeraction do
    trigger
    action_type              { 100 }
    add_attribute(:sequence) { 0 }
    send_to                  { 'contact_main' }
    data                     { { text_message: 'asdfg' } }
  end
end
