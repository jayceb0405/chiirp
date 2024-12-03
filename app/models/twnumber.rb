# frozen_string_literal: true

# app/models/twnumber.rb
class Twnumber < ApplicationRecord
  belongs_to :client
  belongs_to :dlc10_campaign,         class_name: 'Clients::Dlc10::Campaign', optional: true
  belongs_to :vm_greeting_recording,  class_name: :VoiceRecording, optional: true
  belongs_to :announcement_recording, class_name: :VoiceRecording, optional: true

  has_many   :twnumberusers, dependent: :delete_all
  has_many   :users,         through: :twnumberusers

  store_accessor :data, :hangup_detection_duration, :incoming_call_routing, :pass_routing, :pass_routing_method, :pass_routing_phone_number, :vendor_order_id, :pass_routing_ring_duration

  validates :phonenumber, presence: true, uniqueness: true, length: { is: 10 }

  after_initialize  :apply_defaults
  before_validation :normalize_phone
  before_destroy    :delete_leased_number

  scope :client_phone_numbers, ->(client_id) {
    where(client_id:)
  }
  scope :user_phone_numbers, ->(user_id) {
    joins(:twnumberusers)
      .where(twnumberusers: { user_id: })
  }
  scope :contact_phone_numbers, ->(contact_id) {
    joins(client: :contacts)
      .where(contacts: { id: contact_id })
      .where(phonenumber: Messages::Message.joins(:contact).where(contacts: { id: contact_id }).group(:to_phone, :from_phone).pluck(:to_phone, :from_phone).flatten.uniq)
  }

  def def_user
    Twnumberuser.find_by(twnumber_id: self.id, def_user: true)&.user
  end

  def def_user_name
    self.def_user&.fullname || 'Unassigned'
  end

  # delete a number before destroying Twnumber
  # before_destroy :delete_leased_number
  def delete_leased_number
    PhoneNumbers::Router.destroy(phone_vendor: self.phone_vendor, client_name: self.client.name, vendor_id: self.vendor_id, phone_number: self.phonenumber)
  end

  def name
    read_attribute(:name).nil? || read_attribute(:name).strip.empty? ? self.phonenumber : read_attribute(:name)
  end

  def next_pass_routing_phone_number(to_phone)
    next_phone = ''

    pass_routing_position = if self.pass_routing.include?('phone_number') && self.pass_routing_phone_number == to_phone
                              self.pass_routing.index('phone_number')
                            elsif (user = User.where(client_id: self.client_id, id: self.pass_routing).find_by('data @> ?', { phone_in: to_phone }.to_json))

                              if self.pass_routing.include?('def_user') && user.phone_in == to_phone
                                self.pass_routing.index('def_user')
                              else
                                self.pass_routing.index(user.id.to_s)
                              end
                            else
                              self.pass_routing.length
                            end

    while (pass_routing_position.to_i + 1) < self.pass_routing.length && next_phone.blank?

      next_phone = if self.pass_routing[pass_routing_position + 1] == 'phone_number'
                     self.pass_routing_phone_number
                   elsif self.pass_routing[pass_routing_position + 1] == 'def_user'

                     if (contact = Contact.where(client_id: self.client_id).joins(:contact_phones).find_by(contact_phones: { phone: to_phone }))
                       contact.user.phone_in
                     end
                   elsif (user = User.find_by(client_id: self.client_id, id: self.pass_routing[pass_routing_position + 1]))

                     user.phone_in
                   end

      pass_routing_position += 1
    end

    next_phone
  end

  def notify_on_phone_number_destroyed(twnumber)
    Integrations::Slack::PostMessageJob.perform_later(
      token:   Rails.application.credentials[:slack][:token],
      channel: 'client-activity',
      content: "#{twnumber.client.name} (#{twnumber.client_id}) released a phone number (#{ActionController::Base.helpers.number_to_phone(twnumber.phonenumber)}) ordered only #{((Time.current - twnumber.created_at) / 60 / 60 / 24).to_i} days ago."
    )
  end

  def phone_number_status_update
    return if self.vendor_order_id.blank?

    result = PhoneNumbers::Router.status_update(self.vendor_order_id)

    return unless result[:success]

    if result[:completed] && self.phonenumber == result[:phone_number]
      self.update(vendor_id: self.vendor_order_id, vendor_order_id: '')
    elsif result[:failed] && self.phonenumber == result[:phone_number]
      self.destroy
    else
      self.delay(
        run_at:   15.seconds.from_now,
        priority: DelayedJob.job_priority('phone_number_status_update'),
        queue:    DelayedJob.job_queue('phone_number_status_update'),
        process:  'phone_number_status_update'
      ).phone_number_status_update
    end
  end

  private

  def after_create_commit_actions
    super

    self.twnumberusers.create(user_id: self.client.def_user_id) if self.twnumberusers.empty?
  end

  def after_destroy_commit_actions
    super

    notify_on_phone_number_destroyed(self) if self.created_at >= 5.days.ago
  end

  def apply_defaults
    self.hangup_detection_duration  ||= 15 # seconds
    self.incoming_call_routing      ||= ''
    self.pass_routing               ||= %w[def_user]
    self.pass_routing_method        ||= 'chain'
    self.pass_routing_phone_number  ||= ''
    self.pass_routing_ring_duration ||= 0
    self.vendor_order_id            ||= ''
  end

  def normalize_phone
    self.phonenumber = self.phonenumber.clean_phone(self.client.primary_area_code)
  end
end
