# frozen_string_literal: true

# app/helpers/contacts/custom_field_helper.rb
module Contacts
  module CustomFieldHelper
    # create a ClientCustomField input/select
    # <%= contact_custom_field_input(
    #   custom_field: ClientCustomField,
    #   object_name: 'string',
    #   contact: Contact,
    #   var_value: 'string',
    #   row: { class: 'string', id: 'string', display: boolean, columns: [l, r] },
    #   col: { class: 'string', id: 'string', display: boolean },
    #   form_group: { class: 'string', id: 'string', display: boolean },
    #   label: { class: 'string', id: 'string', title: 'string', display: boolean },
    #   html_options: { class: 'string', id: 'string', placeholder: 'string', required: boolean, disabled: boolean, autofocus: boolean },
    #   google_calendar: { calendar_ids: Array },
    #   prepends: [{ button: boolean, label: 'string', id: 'string', display: boolean, disabled: boolean }, ...],
    #   appends: [{ button: boolean, label: 'string', id: 'string', display: boolean, disabled: boolean }, ...],
    #   messages: { note: 'string' }
    # ) %>
    def contact_custom_field_input(args = {})
      return '' unless args.dig(:custom_field).is_a?(ClientCustomField) && args.dig(:object_name).to_s.present?

      case args[:custom_field].var_type
      when 'string'
        ccf_string_field(args)
      when 'numeric'
        ccf_numeric_field(args)
      when 'stars'
        ccf_stars_field(args)
      when 'currency'
        ccf_currency_field(args)
      when 'date'
        ccf_date_field(args)
      else
        ''
      end
    end

    def contact_custom_fields_form_fields(client, form_fields)
      all_fields = ::Webhook.internal_key_hash(client, 'contact', %w[personal phones custom_fields])
      response = {}

      form_fields&.each do |key, value|
        next unless value&.dig('show').to_i == 1

        response[key] = { 'name' => all_fields.dig(key).to_s }

        value.each do |k, v|
          response[key][k] = v
        end
      end

      response.sort_by { |_key, value| value['order'].to_i }.to_h
    end

    private

    def ccf_var_value(var_value, custom_field, contact)
      response = (var_value.presence || custom_field.attributes.dig('var_value').presence || contact&.contact_custom_fields&.find_by(client_custom_field_id: custom_field.id)&.var_value.presence || '').to_s
      response = contact&.send(custom_field.var_var).presence if response.blank? && contact.respond_to?(custom_field.var_var)
      response = contact&.contact_phones&.find_by(label: custom_field.var_var.split('_').last, primary: true)&.phone.to_s if response.blank? && custom_field.var_var.split('_').first.casecmp?('phone')
      response = contact&.contact_phones&.find_by(label: custom_field.var_var.split('_').last)&.phone.to_s if response.blank? && custom_field.var_var.split('_').first.casecmp?('phone')

      response
    end

    def ccf_currency_field(args)
      html_options               = args.dig(:html_options) || {}
      html_options[:min]         = (args.dig(:html_options, :min) || args[:custom_field].var_options[:currency_min].to_d || 0).to_d.to_s
      html_options[:max]         = (args.dig(:html_options, :max) || args[:custom_field].var_options[:currency_max].to_d || 999_999_999_999_999_999_999.99).to_d.to_s
      html_options[:step]        = args.dig(:html_options, :step) || 0.01
      html_options[:placeholder] = args.dig(:html_options, :placeholder) || args[:custom_field].var_placeholder || "Enter #{args[:custom_field].var_name}"
      prepends                   = args.dig(:prepends) || {}
      prepends[:icon]            = args.dig(:prepends, :icon) || 'dollar-sign'
      messages                   = args.dig(:messages) || {}
      messages[:note]            = args.dig(:messages, :note) || "Between #{number_to_currency((args[:custom_field].var_options[:currency_min] || 0).to_d)} & #{number_to_currency((args[:custom_field].var_options[:currency_max] || 999_999_999_999_999_999_999.99).to_d)}."

      bootstrap_number_field(
        field:        "#{args[:object_name]}[#{args[:custom_field].id || args[:custom_field].var_var}]",
        value:        self.ccf_var_value(args.dig(:var_value), args[:custom_field], args.dig(:contact)).presence || args[:custom_field].var_options[:currency_min].to_d || 0.0,
        row:          self.ccf_row(args),
        col:          args.dig(:col) || {},
        form_group:   args.dig(:form_group) || {},
        label:        self.ccf_label(args),
        html_options:,
        prepends:,
        appends:      args.dig(:appends) || {},
        messages:
      )
    end

    def ccf_date_field(args)
      contact                    = args.dig(:contact)
      html_options               = args.dig(:html_options) || {}
      html_options[:id]          = args.dig(:html_options, :id) || "client_custom_field_date_#{args[:custom_field].id}"
      html_options[:placeholder] = args.dig(:html_options, :placeholder) || args[:custom_field].var_placeholder || "Select #{args[:custom_field].var_name}"
      calendar_ids               = args.dig(:google_calendar, :calendar_ids) || []
      var_value                  = self.ccf_var_value(args.dig(:var_value), args[:custom_field], contact)

      bootstrap_calendar_field(
        field:           "#{args[:object_name]}[#{args[:custom_field].id || args[:custom_field].var_var}]",
        value:           var_value.present? && Time.use_zone(args[:custom_field].client.time_zone) { Chronic.parse(var_value) } ? Time.use_zone(args[:custom_field].client.time_zone) { Chronic.parse(var_value) }.strftime('%m/%d/%Y %I:%M %p') : '',
        modal:           { id: 'dash_modal' },
        row:             self.ccf_row(args),
        col:             args.dig(:col) || {},
        form_group:      args.dig(:form_group) || {},
        label:           self.ccf_label(args),
        html_options:,
        flatpickr:       { include_time: true, mode: 'single' },
        google_calendar: { calendar_ids:, title: "#{contact&.fullname&.possessive} #{html_options[:placeholder]}", description: '', location: '', recurrence: '', attendee_emails: contact&.email.to_s }
      )
    end

    def ccf_label(args)
      response         = args.dig(:label) || {}
      response[:title] = if args.dig(:label, :display).nil? ? true : args.dig(:display).to_bool
                           args.dig(:label, :title) || args[:custom_field].var_name
                         else
                           ''
                         end

      response
    end

    def ccf_numeric_field(args)
      html_options               = args.dig(:html_options) || {}
      html_options[:min]         = args.dig(:html_options, :min) || args[:custom_field].var_options[:numeric_min] || 0
      html_options[:max]         = args.dig(:html_options, :max) || args[:custom_field].var_options[:numeric_max] || 999_999_999_999_999_999_999.99
      html_options[:step]        = args.dig(:html_options, :step) || 'any'
      html_options[:placeholder] = args.dig(:html_options, :placeholder) || args[:custom_field].var_placeholder || "Enter #{args[:custom_field].var_name}"
      messages                   = args.dig(:messages) || {}
      messages[:note]            = args.dig(:messages, :note) || "Between #{args[:custom_field].var_options[:numeric_min] || 0} & #{args[:custom_field].var_options[:numeric_max] || 999_999_999_999_999_999_999.99}."

      bootstrap_number_field(
        field:        "#{args[:object_name]}[#{args[:custom_field].id || args[:custom_field].var_var}]",
        value:        self.ccf_var_value(args.dig(:var_value), args[:custom_field], args.dig(:contact)),
        row:          self.ccf_row(args),
        col:          args.dig(:col) || {},
        form_group:   args.dig(:form_group) || {},
        label:        self.ccf_label(args),
        html_options:,
        prepends:     args.dig(:prepends) || {},
        appends:      args.dig(:appends) || {},
        messages:
      )
    end

    def ccf_row(args)
      response         = args.dig(:row) || {}
      response[:class] = (args.dig(:row, :class).to_s.split << (args[:custom_field].var_important ? '' : 'not_important')).compact_blank.join(' ')

      response
    end

    def ccf_stars_field(args)
      html_options            = args.dig(:html_options) || {}
      html_options[:maxstars] = args.dig(:html_options, :maxstars) || args[:custom_field].var_options[:stars_max].to_i || 5

      render partial: 'snippets/star_field', locals: {
        field:        "#{args[:object_name]}[#{args[:custom_field].id || args[:custom_field].var_var}]",
        value:        self.ccf_var_value(args.dig(:var_value), args[:custom_field], args.dig(:contact)).to_i,
        row:          self.ccf_row(args),
        col:          args.dig(:col) || {},
        form_group:   args.dig(:form_group) || {},
        label:        self.ccf_label(args),
        html_options:,
        messages:     args.dig(:messages) || {}
      }
    end

    def ccf_string_field(args)
      if args[:custom_field].var_options.is_a?(Hash) && args[:custom_field].var_options.dig(:string_options).present?
        bootstrap_select_tag(
          field:        "#{args[:object_name]}[#{args[:custom_field].id || args[:custom_field].var_var}]",
          row:          self.ccf_row(args),
          col:          args.dig(:col) || {},
          form_group:   args.dig(:form_group) || {},
          label:        self.ccf_label(args),
          html_options: args.dig(:html_options) || {},
          options:      { for_select: options_for_select(args[:custom_field].string_options_for_select, self.ccf_var_value(args.dig(:var_value), args[:custom_field], args.dig(:contact))), blank: args[:custom_field].var_placeholder.presence || "Select #{args[:custom_field].var_name}" },
          messages:     args.dig(:messages) || {}
        )
      elsif args[:custom_field].var_name.casecmp?('state')
        bootstrap_select_tag(
          field:        "#{args[:object_name]}[#{args[:custom_field].id || args[:custom_field].var_var}]",
          row:          self.ccf_row(args),
          col:          args.dig(:col) || {},
          form_group:   args.dig(:form_group) || {},
          label:        self.ccf_label(args),
          html_options: args.dig(:html_options) || {},
          options:      { for_select: options_for_state(country: %w[US CA], selected: self.ccf_var_value(args.dig(:var_value), args[:custom_field], args.dig(:contact))), blank: args[:custom_field].var_placeholder.presence || "Select #{args[:custom_field].var_name}" },
          messages:     args.dig(:messages) || {}
        )
      else
        html_options               = args.dig(:html_options) || {}
        html_options[:placeholder] = args.dig(:html_options, :placeholder) || args[:custom_field].var_placeholder || "Enter #{args[:custom_field].var_name}"

        if args[:custom_field].var_var.include?('phone')
          html_options[:minlength]   = 10
          html_options[:maxlength]   = 10
          html_options[:onkeypress]  = 'return /\d/.test(String.fromCharCode(((event||window.event).which||(event||window.event).which)));'
        end

        bootstrap_text_field(
          field:        "#{args[:object_name]}[#{args[:custom_field].id || args[:custom_field].var_var}]",
          value:        self.ccf_var_value(args.dig(:var_value), args[:custom_field], args.dig(:contact)),
          row:          self.ccf_row(args),
          col:          args.dig(:col) || {},
          form_group:   args.dig(:form_group) || {},
          label:        self.ccf_label(args),
          html_options:,
          messages:     args.dig(:messages) || {}
        )
      end
    end
  end
end
