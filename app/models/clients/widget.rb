# frozen_string_literal: true

# app/models/clients/widget.rb
module Clients
  # Clients::Widget data processing
  class Widget < ApplicationRecord
    self.table_name = 'client_widgets'

    has_one_attached :button_image

    belongs_to :client
    belongs_to :group, optional: true
    belongs_to :stage, optional: true
    belongs_to :tag,   optional: true

    # version v2
    store_accessor :formatting, :auto_popup, :background_color, :bubble_color, :bubble_text, :default_question, :image_user_id,
                   :show_bubble, :show_question, :show_user_avatar, :submit_button_color, :submit_button_text, :title, :tag_line, :text_message

    # version v3
    store_accessor :formatting, :version, :form_fields,
                   :bb_bg_color, :bb_font, :bb_show, :bb_text, :bb_text_color, :bb_timeout, :bb_user_avatar, :bb_user_id,
                   :b_bg_color, :b_icon, :b_icon_color,
                   :w_auto_popup, :w_auto_popup_timeout, :w_bg_color, :w_def_question, :w_dd_comment, :w_dd_actions, :w_dd_options, :w_font, :w_footer_color,
                   :w_header_color, :w_show_question, :w_submit_button_color, :w_submit_button_text, :w_tag_line, :w_text_message, :w_title, :w_user_avatar, :w_user_id

    validate :count_is_approved, on: [:create]

    after_initialize :apply_new_record_data

    scope :for_client, ->(client_id) {
      where(client_id:)
    }
    scope :by_tenant, ->(tenant = 'chiirp') {
      joins(:client)
        .where(clients: { tenant: })
    }

    # change the widget_key
    # client_widget.new_widget_key
    def new_widget_key
      self.widget_key   = RandomCode.new.create(20)
      self.widget_key   = RandomCode.new.create(20) while Clients::Widget.find_by(widget_key: self.widget_key)
    end

    # change the share_code
    # client_widget.new_share_code
    def new_share_code
      self.share_code = RandomCode.new.create(20)
      self.share_code = RandomCode.new.create(20) while Clients::Widget.find_by(share_code: self.share_code)
    end

    private

    def apply_new_record_data
      case self.version
      when 'v2'
        self.auto_popup                     ||= 0
        self.background_color               ||= '#ffffff'
        self.bubble_color                   ||= '#fff0a0'
        self.bubble_text                    ||= 'Hi 👋!  Have a Question?  Text us now.'
        self.default_question               ||= ''
        self.image_user_id                  ||= 0
        self.show_bubble                      = self.show_bubble.to_bool
        self.show_question                    = self.show_question.nil? ? true : self.show_question
        self.show_user_avatar               ||= 0
        self.submit_button_color            ||= '#269af1'
        self.submit_button_text             ||= 'Text Me!'
        self.title                          ||= 'Hi, welcome! 👋'
        self.tag_line                       ||= "We're here to help you succeed!"
        self.text_message                   ||= 'What can we do for you?'
      when 'v3'
        self.bb_bg_color                    ||= '#fff0a0'
        self.bb_font                        ||= 'Montserrat'
        self.bb_show                          = self.bb_show.nil? ? false : self.bb_show
        self.bb_text                        ||= 'Hi 👋!  Have a Question?  Text us now.'
        self.bb_text_color                  ||= '#ffffff'
        self.bb_timeout                     ||= 5
        self.bb_user_avatar                   = self.bb_user_avatar.nil? ? false : self.bb_user_avatar
        self.bb_user_id                     ||= 0

        self.b_bg_color                     ||= '#ffffff'
        self.b_icon                         ||= 'default'
        self.b_icon_color                   ||= '#888c9b'

        self.w_auto_popup                     = self.w_auto_popup.nil? ? false : self.w_auto_popup
        self.w_auto_popup_timeout           ||= 4
        self.w_bg_color                     ||= '#ffffff'
        self.w_def_question                 ||= ''
        self.w_dd_comment                   ||= ''
        self.w_dd_options                   ||= []
        self.w_dd_actions                   ||= {}
        self.w_font                         ||= 'Montserrat'
        self.w_footer_color                 ||= '#ffffff'
        self.w_header_color                 ||= '#ffffff'
        self.w_show_question                  = self.w_show_question.nil? ? true : self.w_show_question
        self.w_submit_button_color          ||= '#269af1'
        self.w_submit_button_text           ||= 'Text Me!'
        self.w_tag_line                     ||= "We're here to help you succeed!"
        self.w_text_message                 ||= 'What can we do for you?'
        self.w_title                        ||= 'Hi, welcome! 👋'
        self.w_user_avatar                    = self.w_user_avatar.nil? ? true : self.w_user_avatar
        self.w_user_id                      ||= 0

        self.form_fields                    ||= {}
        self.version                        ||= 'v3'
      end

      self.new_widget_key if self.new_record?
      self.new_share_code if self.new_record?
    end

    def count_is_approved
      errors.add(:base, "Maximum SiteChat buttons for #{self.client.name} has been met.") unless self.client.client_widgets.count < self.client.widgets_count.to_i
    end
  end
end
