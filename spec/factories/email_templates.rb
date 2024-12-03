# frozen_string_literal: true

FactoryBot.define do
  factory :email_template do
    client
    sequence(:name) { |n| "Email Template #{n}" }
    subject { 'This is my subject' }
    content { 'Hello world!' }
  end
end
