# frozen_string_literal: true

# app/models/client_transaction.rb
class ClientTransaction < ApplicationRecord
  belongs_to :client

  serialize :old_data, coder: YAML, type: Hash
  store_accessor :data, :contact_id, :trans_id, :message_id, :aiagent_id, :aiagent_session_id

  after_initialize :apply_defaults, if: :new_record?

  DESCRIPTIONS = {
    'added_charge'               => 'Additional Account Charges',
    'aiagent_message_credits'    => 'AI Agent Message Credits',
    'aiagent_overage_charge'     => 'AI Agent Overage Charge',
    'aiagent_base_charge'        => 'AI Agent Monthly Base Charge',
    'user_contact_form_charge'   => 'Charge for QuickPage',
    'campaign_charge'            => 'Charge for Campaign',
    'credit_charge'              => 'Charge for Additional Credits',
    'credits_added'              => 'Credits Added to Account',
    'mo_charge'                  => 'Monthly Charges',
    'phone_call_credits'         => 'Phone Call Credits',
    'rvm_credits'                => 'Ringless Voicemail Credits',
    'startup_costs'              => 'Setup Fees',
    'text_image_credits'         => 'Text Image Credits',
    'text_message_credits'       => 'Text Message Credits',
    'video_call_credits'         => 'Video Call Credits',
    'dlc10_campaign_mo_credits'  => '10DLC Campaign Monthly Credits',
    'dlc10_campaign_qtr_credits' => '10DLC Campaign Quarterly Credits',
    'dlc10_brand_credits'        => '10DLC Brand Registration Credits',
    'dlc10_campaign_charge'      => '10DLC Campaign Submittal Charge',
    'dlc10_campaign_mo_charge'   => '10DLC Campaign Monthly Charge',
    'dlc10_brand_charge'         => '10DLC Brand Registration Charge'
  }.freeze

  def self.description(setting_key)
    DESCRIPTIONS.dig(setting_key).presence || 'Unknown'
  end

  def description
    DESCRIPTIONS.dig(self.setting_key).presence || 'Unknown'
  end

  def self.name_hash_type(key)
    # return a type for each setting_key key
    if %w[aiagent_message_credits credits_added dlc10_brand_credits dlc10_campaign_mo_credits dlc10_campaign_qtr_credits mo_credits phone_call_credits rvm_credits text_image_credits text_message_credits].include?(key.to_s)
      'c'
    elsif %w[added_charge credit_charge dlc10_brand_charge dlc10_campaign_charge dlc10_campaign_mo_charge mo_charge startup_costs].include?(key.to_s)
      '$'
    end
  end

  private

  def apply_defaults
    self.contact_id         ||= 0
    self.trans_id           ||= ''
    self.message_id         ||= 0
    self.aiagent_id         ||= 0
    self.aiagent_session_id ||= 0
  end
end
