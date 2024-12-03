# frozen_string_literal: true

# app/helpers/looper_form_builder.rb
class LooperFormBuilder < ActionView::Helpers::FormBuilder
  include ActionView::Helpers::FormTagHelper
  include ActionView::Helpers::FormOptionsHelper
  include ActionView::Helpers::TagHelper
  include ActionView::Context
  include ApplicationHelper

  # rubocop:disable Rails/OutputSafety

  # <%= f.check_box :method, {
  #   row: { class: 'string', id: 'string', display: boolean, columns: [l, r] },
  #   col: { class: 'string', id: 'string', display: boolean },
  #   label: { class: 'string', id: 'string', title: 'string' },
  #   checkboxes: [{ field: 'string', label: 'string', class: 'string', id: 'string', checked: true/false, values: [on, off] }, ...],
  #   messages: { note: 'string' }
  # } %>
  def check_box(method, options = {})
    columns             = columns(options.dig(:row, :columns))
    checkboxes          = ''
    html_option_classes = %w[custom-control-input]

    options.dig(:checkboxes).each do |checkbox|
      html_options = {}
      html_options[:class]   = html_option_classes + checkbox.dig(:class).to_s.split
      html_options[:id]      = (checkbox.dig(:id) || "checkbox_#{rand(100_000)}").to_s
      html_options[:checked] = checkbox[:checked].to_bool unless checkbox.dig(:checked).nil?
      values = [checkbox.dig(:values) || [true, false]].flatten
      values = values.length == 1 ? [values[0], false] : [true, false] unless values.length == 2
      checkboxes += content_tag(:div, class: %w[custom-control custom-checkbox]) do
        super(checkbox.dig(:field).to_sym, html_options, values[0].to_s, values[1].to_s) +
          label_tag(html_options[:id], checkbox.dig(:label).to_s, { class: %w[custom-control-label] })
      end
    end

    content_tag(:div, class: form_row_class(options.dig(:row, :class)), id: options.dig(:row, :id).to_s, style: (options.dig(:row, :display).nil? || options[:row][:display].to_bool ? '' : 'display:none;').to_s) do
      content_tag(:label, label_string(options.dig(:label, :title), options.dig(:messages, :note), options.dig(:html_options, :required).to_bool).html_safe, for: method, class: label_class(options.dig(:label, :class).to_s, columns), id: options.dig(:label, :id).to_s) +
        content_tag(:div, class: col_class(options.dig(:col, :class).to_s, columns), id: options.dig(:col, :id).to_s, style: (options.dig(:col, :display).nil? || options.dig(:col, :display).to_bool ? '' : 'display:none;').to_s) do
          checkboxes.html_safe
        end
    end
  end

  # <%= f.copy_field :method, {
  #   row: { class: 'string', id: 'string', display: boolean, columns: [l, r] },
  #   col: { class: 'string', id: 'string', display: boolean },
  #   form_group: { class: 'string', id: 'string', display: boolean },
  #   label: { class: 'string', id: 'string', title: 'string' },
  #   html_options: { value: 'string', class: 'string', id: 'string', placeholder: 'string' },
  #   prepends: [{ button: boolean, label: 'string', id: 'string', display: boolean, disabled: boolean }, ...],
  #   messages: { note: 'string' }
  # } %>
  def copy_field(method, options = {})
    options[:html_options] = {} unless options.dig(:html_options)
    options[:html_options][:id] = "copy_field_#{rand(100_000)}" unless options.dig(:html_options, :id)
    options[:html_options][:disabled] = true
    options[:appends] = [{ button: true, label: '<i class="fa fa-clipboard"></i>'.html_safe, id: "copy_button_#{rand(100_000)}", onclick: "event.preventDefault();copyToClipboard('#{options[:html_options][:id]}');" }]
    text_field(method, options)
  end

  # <%= f.email_field :method, {
  #   row: { class: 'string', id: 'string', display: boolean, columns: [l, r] },
  #   col: { class: 'string', id: 'string', display: boolean },
  #   form_group: { class: 'string', id: 'string', display: boolean },
  #   label: { class: 'string', id: 'string', title: 'string' },
  #   html_options: { value: 'string', class: 'string', id: 'string', placeholder: 'string', minlength: integer, maxlength: integer, size: integer, typeahead_client: Client, typeahead_drop_up: boolean, required: boolean, disabled: boolean, autofocus: boolean },
  #   prepends: [{ button: boolean, label: 'string', id: 'string', display: boolean, disabled: boolean }, ...],
  #   appends: [{ button: boolean, label: 'string', id: 'string', display: boolean, disabled: boolean }, ...],
  #   messages: { note: 'string' }
  # } %>
  def email_field(method, options = {})
    html_options = html_options(options.dig(:html_options))
    columns      = columns(options.dig(:row, :columns))
    col_class    = col_class(options.dig(:col, :class).to_s, columns)
    label_class  = label_class(options.dig(:label, :class).to_s, columns)
    prepends     = input_field_prepends(options.dig(:prepends) || [{ button: false, label: '<i class="fa fa-envelope"></i>' }])
    appends      = input_field_appends(options.dig(:appends))

    response = content_tag(:div, class: form_row_class(options.dig(:row, :class)), id: options.dig(:row, :id).to_s, style: (options.dig(:row, :display).nil? || options[:row][:display].to_bool ? '' : 'display:none;').to_s) do
      content_tag(:label, label_string(options.dig(:label, :title), options.dig(:messages, :note), options.dig(:html_options, :required).to_bool).html_safe, for: method, class: label_class, id: options.dig(:label, :id).to_s) +
        content_tag(:div, class: col_class, id: options.dig(:col, :id).to_s, style: (options.dig(:col, :display).nil? || options.dig(:col, :display).to_bool ? '' : 'display:none;').to_s) do
          content_tag(:div, class: %w[form-group flex-wrap] + options.dig(:form_group, :class).to_s.split, id: options.dig(:form_group, :id).to_s, style: (options.dig(:form_group, :display).nil? || options.dig(:form_group, :display).to_bool ? '' : 'display:none;').to_s) do
            content_tag(:div, class: %w[input-group has-typeahead-scrollable] + (appends.present? ? ['input-group-alt'] : [])) do
              prepends.html_safe +
                super(method, objectify_options(html_options)) +
                appends.html_safe
            end
          end
        end
    end

    response += content_tag(:script, typeahead_script(html_options[:id], options[:html_options][:typeahead_client], options[:html_options][:typeahead_drop_up].to_bool)) if options.dig(:html_options, :typeahead_client).is_a?(Client)

    response
  end

  # <%= f.number_field :method, {
  #   row: { class: 'string', id: 'string', display: boolean, columns: [l, r] },
  #   col: { class: 'string', id: 'string', display: boolean },
  #   form_group: { class: 'string', id: 'string', display: boolean },
  #   label: { class: 'string', id: 'string', title: 'string' },
  #   html_options: { value: 'integer/decimal', class: 'string', id: 'string', min: integer/float/decimal, max: integer/float/decimal, step: integer/float/decimal, required: boolean, disabled: boolean, autofocus: boolean },
  #   prepends: [{ button: boolean, label: 'string', id: 'string', display: boolean, disabled: boolean }, ...],
  #   appends: [{ button: boolean, label: 'string', id: 'string', display: boolean, disabled: boolean }, ...],
  #   messages: { note: 'string' }
  # } %>
  def number_field(method, options = {})
    html_options = html_options(options.dig(:html_options))
    columns      = columns(options.dig(:row, :columns))
    col_class    = col_class(options.dig(:col, :class).to_s, columns)
    label_class  = label_class(options.dig(:label, :class).to_s, columns)
    prepends     = input_field_prepends(options.dig(:prepends) || [{ button: false, label: '<i class="fa fa-hashtag"></i>' }])
    appends      = input_field_appends(options.dig(:appends))

    response = content_tag(:div, class: form_row_class(options.dig(:row, :class)), id: options.dig(:row, :id).to_s, style: (options.dig(:row, :display).nil? || options[:row][:display].to_bool ? '' : 'display:none;').to_s) do
      content_tag(:label, label_string(options.dig(:label, :title), options.dig(:messages, :note), options.dig(:html_options, :required).to_bool).html_safe, for: method, class: label_class, id: options.dig(:label, :id).to_s) +
        content_tag(:div, class: col_class, id: options.dig(:col, :id).to_s, style: (options.dig(:col, :display).nil? || options.dig(:col, :display).to_bool ? '' : 'display:none;').to_s) do
          content_tag(:div, class: %w[form-group flex-wrap] + options.dig(:form_group, :class).to_s.split, id: options.dig(:form_group, :id).to_s, style: (options.dig(:form_group, :display).nil? || options.dig(:form_group, :display).to_bool ? '' : 'display:none;').to_s) do
            content_tag(:div, class: %w[input-group has-typeahead-scrollable] + (appends.present? ? ['input-group-alt'] : [])) do
              prepends.html_safe +
                super(method, objectify_options(html_options)) +
                appends.html_safe
            end
          end
        end
    end

    response += content_tag(:script, typeahead_script(html_options[:id], options[:html_options][:typeahead_client], options[:html_options][:typeahead_drop_up].to_bool)) if options.dig(:html_options, :typeahead_client).is_a?(Client)

    response
  end

  # <%= f.password_field :method, {
  #   row: { class: 'string', id: 'string', display: boolean, columns: [l, r] },
  #   col: { class: 'string', id: 'string', display: boolean },
  #   form_group: { class: 'string', id: 'string', display: boolean },
  #   label: { class: 'string', id: 'string', title: 'string' },
  #   html_options: { value: 'string', class: 'string', id: 'string', placeholder: 'string', minlength: integer, maxlength: integer, size: integer, required: boolean, disabled: boolean, autofocus: boolean },
  #   prepends: [{ button: boolean, label: 'string', id: 'string', display: boolean, disabled: boolean }, ...],
  #   appends: [{ button: boolean, label: 'string', id: 'string', display: boolean, disabled: boolean }, ...],
  #   messages: { note: 'string' }
  # } %>
  def password_field(method, options = {})
    html_options = html_options(options.dig(:html_options))
    columns      = columns(options.dig(:row, :columns))
    col_class    = col_class(options.dig(:col, :class).to_s, columns)
    label_class  = label_class(options.dig(:label, :class).to_s, columns)
    prepends     = input_field_prepends(options.dig(:prepends) || [{ button: false, label: '<i class="fa fa-key"></i>' }])
    appends      = input_field_appends(options.dig(:appends))

    content_tag(:div, class: form_row_class(options.dig(:row, :class)), id: options.dig(:row, :id).to_s, style: (options.dig(:row, :display).nil? || options[:row][:display].to_bool ? '' : 'display:none;').to_s) do
      content_tag(:label, label_string(options.dig(:label, :title), options.dig(:messages, :note), options.dig(:html_options, :required).to_bool).html_safe, for: method, class: label_class, id: options.dig(:label, :id).to_s) +
        content_tag(:div, class: col_class, id: options.dig(:col, :id).to_s, style: (options.dig(:col, :display).nil? || options.dig(:col, :display).to_bool ? '' : 'display:none;').to_s) do
          content_tag(:div, class: %w[form-group] + options.dig(:form_group, :class).to_s.split, id: options.dig(:form_group, :id).to_s, style: (options.dig(:form_group, :display).nil? || options.dig(:form_group, :display).to_bool ? '' : 'display:none;').to_s) do
            content_tag(:div, class: %w[input-group flex-wrap] + (appends.present? ? ['input-group-alt'] : [])) do
              prepends.html_safe +
                super(method, objectify_options(html_options)) +
                appends.html_safe
            end
          end
        end
    end
  end

  # <%= f.radio_button :method, {
  #   row: { class: 'string', id: 'string', display: boolean, columns: [l, r] },
  #   col: { class: 'string', id: 'string', display: boolean },
  #   label: { class: 'string', id: 'string', title: 'string' },
  #   buttons: [{ class: 'string', label: 'string', value: 'string', id: 'string', checked: boolean }, ...]
  # } %>
  def radio_button(method, options = {})
    columns              = columns(options.dig(:row, :columns))
    radio_buttons        = ''
    radio_button_classes = %w[custom-control-input]

    options.dig(:buttons).each do |button|
      button_options           = { class: radio_button_classes + button.dig(:class).to_s.split, id: button.dig(:id).to_s }
      button_options[:checked] = button[:checked] if button.dig(:checked)

      radio_buttons += content_tag(:div, class: %w[custom-control custom-radio]) do
        @template.radio_button(@object_name, method, button.dig(:value).to_s, objectify_options(button_options)) +
          content_tag(:label, button.dig(:label).to_s, class: %w[custom-control-label], for: button.dig(:id).to_s)
      end
    end

    content_tag(:div, class: form_row_class(options.dig(:row, :class)), id: options.dig(:row, :id).to_s, style: (options.dig(:row, :display).nil? || options[:row][:display].to_bool ? '' : 'display:none;').to_s) do
      content_tag(:label, options.dig(:label, :title).to_s, for: method, class: label_class(options.dig(:label, :class).to_s, columns), id: options.dig(:label, :id).to_s) +
        content_tag(:div, class: col_class(options.dig(:col, :class).to_s, columns), id: options.dig(:col, :id).to_s, style: (options.dig(:col, :display).nil? || options.dig(:col, :display).to_bool ? '' : 'display:none;').to_s) do
          radio_buttons.html_safe
        end
    end
  end

  # <%= f.select :method, {
  #   row: { class: 'string', id: 'string', display: boolean, columns: [l, r] },
  #   col: { class: 'string', id: 'string', display: boolean },
  #   form_group: { class: 'string', id: 'string', display: boolean },
  #   label: { class: 'string', id: 'string', title: 'string' },
  #   html_options: { class: 'string', id: 'string', data: Hash, required: boolean, disabled: boolean, multi_actions: boolean, multiple: boolean, autofocus: boolean, maxoptions: integer, count_selected_text: 'string', mobile: boolean },
  #   choices: { for_select: choices, array: array, grouped_array: array, selected: 'string/integer', blank: 'string', prompt: 'string', max_options: integer, dynamic: boolean },
  #   prepends: [{ button: boolean, label: 'string', id: 'string', display: boolean, disabled: boolean }, ...],
  #   messages: { note: 'string' }
  # } %>
  def select(method, options = {})
    html_options                   = html_options((options.dig(:html_options) || {}).merge(live_search: options.dig(:choices, :live_search), select: true))
    # html_options                   = html_options({ select: true }.merge(options.dig(:html_options) || {}))
    columns                        = columns(options.dig(:row, :columns))
    col_class                      = col_class(options.dig(:col, :class).to_s, columns)
    label_class                    = label_class(options.dig(:label, :class).to_s, columns)
    prepends                       = input_field_prepends(options.dig(:prepends))
    choices                        = options.dig(:choices, :for_select) unless options.dig(:choices, :for_select).nil?
    choices                        = options_for_select(options.dig(:choices, :array), options.dig(:choices, :selected)) unless options.dig(:choices, :array).nil?
    choices                        = grouped_options_for_select(options.dig(:choices, :grouped_array), options.dig(:choices, :selected)) unless options.dig(:choices, :grouped_array).nil?
    select_options                 = {}
    select_options[:include_blank] = options[:choices][:blank].to_s if options.dig(:choices, :blank).to_s.present?
    select_options[:prompt]        = options[:choices][:prompt].to_s if options.dig(:choices, :prompt).to_s.present?

    content_tag(:div, class: form_row_class(options.dig(:row, :class)), id: options.dig(:row, :id).to_s, style: (options.dig(:row, :display).nil? || options[:row][:display].to_bool ? '' : 'display:none;').to_s) do
      content_tag(:label, label_string(options.dig(:label, :title), options.dig(:messages, :note), options.dig(:html_options, :required).to_bool).html_safe, for: method, class: label_class, id: options.dig(:label, :id).to_s) +
        content_tag(:div, class: col_class, id: options.dig(:col, :id).to_s, style: (options.dig(:col, :display).nil? || options.dig(:col, :display).to_bool ? '' : 'display:none;').to_s) do
          content_tag(:div, class: %w[form-group] + options.dig(:form_group, :class).to_s.split, id: options.dig(:form_group, :id).to_s, style: (options.dig(:form_group, :display).nil? || options.dig(:form_group, :display).to_bool ? '' : 'display:none;').to_s) do
            content_tag(:div, class: %w[input-group no-left-border flex-wrap]) do
              prepends.html_safe +
                @template.select(@object_name, method, choices, select_options, @default_html_options.merge(html_options))
            end
          end
        end
    end +
      (options.dig(:choices, :dynamic).to_bool ? content_tag(:script, dynamic_options_for_select_script(id: html_options[:id]).html_safe) : '')
  end

  # <%= f.submit_buttons(
  #   row: { class: 'string', id: 'string', display: boolean },
  #   buttons: [{ title: 'string', class: 'string', id: 'string', disable_with: 'string', disabled: boolean, display: boolean }, ...]
  # ) %>
  def submit_buttons(options = {})
    buttons = ''

    options.dig(:buttons).each_with_index do |button, index|
      buttons += submit((button.dig(:title) || 'Submit').to_s, { class: (%w[btn btn-info] << (index.zero? ? 'ml-auto' : 'ml-2')) + button.dig(:class).to_s.split, id: button.dig(:id), disabled: button.dig(:disabled).to_bool, data: { 'disable-with': "#{button.dig(:disable_with) || 'Submitting'}..." } })
    end

    content_tag(:div, class: %w[mt-auto] << options.dig(:row, :class), id: options.dig(:row, :id), style: (options.dig(:row, :display).nil? || options[:row][:display].to_bool ? '' : 'display:none;').to_s) do
      content_tag(:div, class: %w[form-actions]) do
        buttons.html_safe
      end
    end
  end

  # <%= f.switch :method, {
  #   row: { class: 'string', id: 'string', display: boolean, columns: [l, r] },
  #   col: { class: 'string', id: 'string', display: boolean },
  #   label: { class: 'string', id: 'string', title: 'string' },
  #   checkboxes: [{ field: 'string', label: 'string', class: 'string', id: 'string', checked: true/false, values: [on, off], note: 'string', disabled: boolean }, ...],
  #   messages: { note: 'string' }
  # } %>
  def switch(method, options = {})
    columns            = columns(options.dig(:row, :columns))
    checkboxes         = ''
    checkbox_classes   = %w[switcher-input]
    form_group_classes = %w[list-group-item d-flex align-items-center p-0 bg-transparent]

    options.dig(:checkboxes).each do |checkbox|
      html_options = {}
      html_options[:class]    = checkbox_classes + checkbox.dig(:class).to_s.split
      html_options[:id]       = checkbox[:id].to_s unless checkbox.dig(:id).nil?
      html_options[:checked]  = checkbox[:checked].to_bool unless checkbox.dig(:checked).nil?
      html_options[:disabled] = checkbox[:disabled].to_bool unless checkbox.dig(:disabled).nil?
      values = [checkbox.dig(:values) || %w[true false]].flatten
      values = values.length == 1 ? [values[0], 'false'] : %w[true false] unless values.length == 2
      checkboxes += content_tag(:div, class: form_group_classes + options.dig(:form_group, :class).to_s.split, id: options.dig(:form_group, :id).to_s, style: (options.dig(:form_group, :display).nil? || options.dig(:form_group, :display).to_bool ? '' : 'display:none;').to_s) do
        content_tag(:label, class: %w[switcher-control switcher-control-lg], style: 'cursor:pointer;') do
          @template.check_box(@object_name, (method == :null ? checkbox.dig(:field).to_sym : method), html_options, values[0].to_s, values[1].to_s) +
            content_tag(:span, nil, class: %w[switcher-indicator]) +
            content_tag(:span, (options.dig(:label, :checked) || '<i class="fa fa-check"></i>').to_s.html_safe, class: %w[switcher-label-on]) +
            content_tag(:span, (options.dig(:label, :unchecked) || '<i class="fa fa-times"></i>').to_s.html_safe, class: %w[switcher-label-off])
        end +
          content_tag(:span, checkbox.dig(:note).to_s, class: %w[pl-2])
      end
    end

    content_tag(:div, class: form_row_class(options.dig(:row, :class)), id: options.dig(:row, :id).to_s, style: (options.dig(:row, :display).nil? || options[:row][:display].to_bool ? '' : 'display:none;').to_s) do
      content_tag(:label, label_string(options.dig(:label, :title), options.dig(:messages, :note), options.dig(:html_options, :required).to_bool).html_safe, for: method, class: label_class(options.dig(:label, :class).to_s, columns), id: options.dig(:label, :id).to_s) +
        content_tag(:div, class: col_class((options.dig(:col, :class).to_s.split << 'mb-3').join(' '), columns), id: options.dig(:col, :id).to_s, style: (options.dig(:col, :display).nil? || options.dig(:col, :display).to_bool ? '' : 'display:none;').to_s) do
          checkboxes.html_safe
        end
    end
  end

  # <%= f.telephone_field :method, {
  #   row: { class: 'string', id: 'string', display: boolean, columns: [l, r] },
  #   col: { class: 'string', id: 'string', display: boolean },
  #   form_group: { class: 'string', id: 'string', display: boolean },
  #   label: { class: 'string', id: 'string', title: 'string' },
  #   html_options: { value: 'string', class: 'string', id: 'string', placeholder: 'string', size: integer, required: boolean, disabled: boolean, autofocus: boolean },
  #   prepends: [{ button: boolean, label: 'string', id: 'string', display: boolean, disabled: boolean }, ...],
  #   appends: [{ button: boolean, label: 'string', id: 'string', display: boolean, disabled: boolean }, ...],
  #   messages: { note: 'string' }
  # } %>
  def telephone_field(method, options = {})
    html_options = html_options(options.dig(:html_options)).merge({ minlength: 10, maxlength: 10, onkeypress: 'return /\d/.test(String.fromCharCode(((event||window.event).which||(event||window.event).which)));' })
    columns      = columns(options.dig(:row, :columns))
    col_class    = col_class(options.dig(:col, :class).to_s, columns)
    label_class  = label_class(options.dig(:label, :class).to_s, columns)
    prepends     = input_field_prepends(options.dig(:prepends) || [{ button: false, label: '<i class="fa fa-phone"></i>' }])
    appends      = input_field_appends(options.dig(:appends))

    content_tag(:div, class: form_row_class(options.dig(:row, :class)), id: options.dig(:row, :id).to_s, style: (options.dig(:row, :display).nil? || options[:row][:display].to_bool ? '' : 'display:none;').to_s) do
      content_tag(:label, label_string(options.dig(:label, :title), options.dig(:messages, :note), options.dig(:html_options, :required).to_bool).html_safe, for: method, class: label_class, id: options.dig(:label, :id).to_s) +
        content_tag(:div, class: col_class, id: options.dig(:col, :id).to_s, style: (options.dig(:col, :display).nil? || options.dig(:col, :display).to_bool ? '' : 'display:none;').to_s) do
          content_tag(:div, class: %w[form-group] + options.dig(:form_group, :class).to_s.split, id: options.dig(:form_group, :id).to_s, style: (options.dig(:form_group, :display).nil? || options.dig(:form_group, :display).to_bool ? '' : 'display:none;').to_s) do
            content_tag(:div, class: %w[input-group flex-wrap] + (appends.present? ? ['input-group-alt'] : [])) do
              prepends.html_safe +
                super(method, objectify_options(html_options)) +
                appends.html_safe
            end
          end
        end
    end
  end

  # <%= f.text_area :method, {
  #   row: { class: 'string', id: 'string', display: boolean, columns: [l, r] },
  #   col: { class: 'string', id: 'string', display: boolean },
  #   form_group: { class: 'string', id: 'string', display: boolean },
  #   label: { class: 'string', id: 'string', title: 'string' },
  #   html_options: { value: 'string', class: 'string', id: 'string', placeholder: 'string', required: boolean, disabled: boolean, autofocus: boolean },
  #   messages: { note: 'string' }
  # } %>
  def text_area(method, options = {})
    html_options = html_options(options.dig(:html_options))
    columns      = columns(options.dig(:row, :columns))
    col_class    = col_class(options.dig(:col, :class).to_s, columns)
    label_class  = label_class(options.dig(:label, :class).to_s, columns)

    content_tag(:div, class: form_row_class(options.dig(:row, :class)), id: options.dig(:row, :id).to_s, style: (options.dig(:row, :display).nil? || options[:row][:display].to_bool ? '' : 'display:none;').to_s) do
      content_tag(:label, label_string(options.dig(:label, :title), options.dig(:messages, :note), options.dig(:html_options, :required).to_bool).html_safe, for: method, class: label_class, id: options.dig(:label, :id).to_s) +
        content_tag(:div, class: col_class, id: options.dig(:col, :id).to_s, style: (options.dig(:col, :display).nil? || options.dig(:col, :display).to_bool ? '' : 'display:none;').to_s) do
          content_tag(:div, class: %w[publisher] + options.dig(:form_group, :class).to_s.split, id: options.dig(:form_group, :id).to_s, style: options.dig(:form_group, :display).nil? || options.dig(:form_group, :display).to_bool ? '' : 'display:none;') do
            content_tag(:div, class: %w[publisher-input pr-0]) do
              super(method, objectify_options(html_options))
            end
          end
        end
    end +
      content_tag(:script, "autosize($('##{html_options[:id]}'));$('##{html_options[:id]}').on('focus', function() {autosize.update($('##{html_options[:id]}'));});".html_safe)
  end

  # <%= f.text_field :method, {
  #   row: { class: 'string', id: 'string', display: boolean, columns: [l, r] },
  #   col: { class: 'string', id: 'string', display: boolean },
  #   form_group: { class: 'string', id: 'string', display: boolean },
  #   input_group: { class: 'string' },
  #   label: { class: 'string', id: 'string', title: 'string' },
  #   html_options: { value: 'string', class: 'string', id: 'string', placeholder: 'string', minlength: integer, maxlength: integer, size: integer, typeahead_client: Client, typeahead_drop_up: boolean, required: boolean, disabled: boolean, autofocus: boolean },
  #   prepends: [{ button: boolean, label: 'string', id: 'string', display: boolean, disabled: boolean, onclick: 'string' }, ...],
  #   appends: [{ button: boolean, label: 'string', id: 'string', display: boolean, disabled: boolean, onclick: 'string' }, ...],
  #   messages: { note: 'string' }
  # } %>
  def text_field(method, options = {})
    html_options = html_options(options.dig(:html_options))
    columns      = columns(options.dig(:row, :columns))
    col_class    = col_class(options.dig(:col, :class).to_s, columns)
    label_class  = label_class(options.dig(:label, :class).to_s, columns)
    prepends     = input_field_prepends(options.dig(:prepends))
    appends      = input_field_appends(options.dig(:appends))

    response = content_tag(:div, class: form_row_class(options.dig(:row, :class)), id: options.dig(:row, :id).to_s, style: (options.dig(:row, :display).nil? || options[:row][:display].to_bool ? '' : 'display:none;').to_s) do
      content_tag(:label, label_string(options.dig(:label, :title), options.dig(:messages, :note), options.dig(:html_options, :required).to_bool).html_safe, for: method, class: label_class, id: options.dig(:label, :id).to_s) +
        content_tag(:div, class: col_class, id: options.dig(:col, :id).to_s, style: (options.dig(:col, :display).nil? || options.dig(:col, :display).to_bool ? '' : 'display:none;').to_s) do
          content_tag(:div, class: %w[form-group flex-wrap] + options.dig(:form_group, :class).to_s.split, id: options.dig(:form_group, :id).to_s, style: (options.dig(:form_group, :display).nil? || options.dig(:form_group, :display).to_bool ? '' : 'display:none;').to_s) do
            content_tag(:div, class: %w[input-group has-typeahead-scrollable] + (appends.present? ? ['input-group-alt'] : []) + options.dig(:input_group, :class).to_s.split) do
              prepends.html_safe +
                super(method, objectify_options(html_options)) +
                appends.html_safe
            end
          end
        end
    end

    response += content_tag(:script, typeahead_script(html_options[:id], options[:html_options][:typeahead_client], options[:html_options][:typeahead_drop_up].to_bool)) if options.dig(:html_options, :typeahead_client).is_a?(Client)

    response
  end

  # <%= f.time_zone_select :method, {
  #   row: { class: 'string', id: 'string', display: boolean, columns: [l, r] },
  #   col: { class: 'string', id: 'string', display: boolean },
  #   form_group: { class: 'string', id: 'string', display: boolean },
  #   label: { class: 'string', id: 'string', title: 'string' },
  #   html_options: { class: 'string', id: 'string', data: Hash, required: boolean, disabled: boolean, multiple: boolean, autofocus: boolean },
  #   choices: { selected: 'string/integer', blank: 'string', prompt: 'string' },
  #   prepends: [{ button: boolean, label: 'string', id: 'string', display: boolean, disabled: boolean }, ...],
  #   messages: { note: 'string' }
  # } %>
  def time_zone_select(method, options = {})
    options[:choices] = {} unless options.dig(:choices).is_a?(Hash)
    options[:choices][:for_select] = time_zone_options_for_select(@object.send(method), ActiveSupport::TimeZone.us_zones)
    select(method, options)
  end

  private

  def columns(column_array)
    columns = [column_array || [3, 9]].flatten

    if columns.length == 2
      columns
    else
      columns.length == 1 ? [columns[0], (12 - columns[0])] : [3, 9]
    end
  end

  def col_class(col_class, columns)
    # ["col-md-#{columns[1]}", col_class, col_class.split.grep(%r{^m-}).any? || col_class.split.grep(%r{^mb-}).any? ? '' : 'mb-3'].reject(&:empty?).join(' ')
    ["col-md-#{columns[1]}", col_class].reject(&:empty?)
  end

  def dynamic_options_for_select_script(args = {})
    id = args.dig(:id).to_s

    '$(function () {' \
      "var content = '<div class=\"d-flex\" id=\"select_dynamic_input_#{id}\"><input type=\"text\" class=\"form-control\" id=\"input_dynamic_input_#{id}\" onKeyDown=\"event.stopPropagation();\" onKeyPress=\"addSelectInpKeyPress(this,event)\" onClick=\"event.stopPropagation()\" placeholder=\"Add item\"> <div class=\"btn btn-icon btn-light ml-2\" id=\"div_dynamic_input_#{id}\"><i class=\"fa fa-plus\"></i></div></div>';" \
      "var divider = $('<option/>').addClass('divider').attr('data-divider', true);" \
      "var divider = '<option data-divider=\"true\"></option>';" \
      "var add_option = $('<option/>', {class: 'addItem'}).attr('data-content', content);" \
      'var myDefaultWhiteList   = $.fn.selectpicker.Constructor.DEFAULTS.whiteList;' \
      "myDefaultWhiteList.input = ['type', 'placeholder', 'onkeypress', 'onkeydown', 'onclick'];" \
      "myDefaultWhiteList.span  = ['onclick'];" \
      "$('##{id}').selectpicker('destroy');" \
      "$('##{id}').prepend(divider).prepend(add_option).selectpicker();" \
      "$('##{id}').off('show.bs.select refreshed.bs.select');" \
      "$('##{id}').on('show.bs.select refreshed.bs.select', function() {" \
      "$('#select_dynamic_input_#{id}').parent('span').removeClass('w-100');" \
      "$('#select_dynamic_input_#{id}').parent('span').addClass('w-100');" \
      "$('#div_dynamic_input_#{id}').off('click');" \
      "$('#div_dynamic_input_#{id}').on('click', function() {" \
      'addSelectItem(this, event);' \
      '});' \
      '});' \
      '});' \
      'function addSelectItem(t, e) {' \
      'e.stopPropagation();' \
      "var txt = $('#input_dynamic_input_#{id}').val().replace(/[|]/g, '');" \
      "if ($.trim(txt) == '') return;" \
      "var se = $('##{id}');" \
      "var o = $('option', se).eq(+2);" \
      "o.before($('<option>', { 'selected': true, 'text': txt}));" \
      "se.selectpicker('refresh');" \
      '}' \
      'function addSelectInpKeyPress(t, e) {' \
      'e.stopPropagation();' \
      'if (e.which == 124) e.preventDefault();' \
      'if (e.which == 13) {' \
      'e.preventDefault();' \
      'addSelectItem($(t).next(), e);' \
      '}' \
      '}'
  end

  def form_row_class(classes)
    classes = if classes.is_a?(String)
                classes.split
              else
                classes.is_a?(Array) ? classes : []
              end
    ((%w[form-row] << (classes.grep(%r{^m-}).any? || classes.grep(%r{^mb-}).any? ? '' : 'mb-0')) + classes).compact_blank
  end

  def html_options(options)
    options ||= {}
    html_options = {}
    html_options[:autofocus]   = options[:autofocus].to_bool unless options.dig(:autofocus).nil?
    html_options[:class]       = %w[form-control typeahead] + options.dig(:class).to_s.split
    # html_options[:data]        = { toggle: 'selectpicker', width: false, container: 'body', mobile: options.dig(:mobile).to_bool }.merge(options.dig(:data) || {}) unless options.dig(:select).nil?
    html_options[:data]        = { toggle: 'selectpicker', 'selected-text-format': 'count > 3', 'actions-box': options.dig(:multi_actions).nil? ? true : options[:multi_actions].to_bool, 'count-selected-text': "{0} #{options.dig(:count_selected_text) || 'items'} selected", 'live-search': options.dig(:live_search).to_bool, 'max-options': options.dig(:maxoptions) || 'false', width: 'fit', container: 'body', mobile: options.dig(:mobile).to_bool }.merge(options.dig(:data) || {}) if options.dig(:select)
    html_options[:disabled]    = options[:disabled].to_bool unless options.dig(:disabled).nil?
    html_options[:id]          = (options.dig(:id) || "id_#{rand(100_000)}").to_s
    html_options[:min]         = options[:min] unless options.dig(:min).nil?
    html_options[:minlength]   = options[:minlength] unless options.dig(:minlength).nil?
    html_options[:max]         = options[:max] unless options.dig(:max).nil?
    html_options[:maxlength]   = options[:maxlength] unless options.dig(:maxlength).nil?
    html_options[:multiple]    = options[:multiple].to_bool unless options.dig(:multiple).nil?
    html_options[:placeholder] = options[:placeholder].to_s unless options.dig(:placeholder).nil?
    html_options[:required]    = options[:required].to_bool unless options.dig(:required).nil?
    html_options[:size]        = options[:size].to_i unless options.dig(:size).nil?
    html_options[:step]        = options[:step] unless options.dig(:step).nil?
    html_options[:value]       = options[:value] unless options.dig(:value).nil?

    html_options
  end

  def input_field_appends(append_array)
    appends = ''

    [append_array || []].flatten.each_with_index do |append, index|
      appends += content_tag(:div, class: 'input-group-append') do
        if append.dig(:button).to_bool
          label_class = %w[input-group-text bg-info border-info text-light pr-2]
          label_class << append[:label_class].to_s if append.dig(:label_class).to_s.present?
          button_tag((append.dig(:label) || 'Submit').to_s.html_safe, { id: append.dig(:id).to_s, class: label_class.join(' '), style: append.dig(:display).nil? || append[:display].to_bool ? '' : 'display:none;', disabled: append.dig(:disabled).to_bool, onclick: append.dig(:onclick).to_s })
        else
          label_class = ['input-group-text']
          label_class << append[:label_class].to_s if append.dig(:label_class).to_s.present?
          content_tag(:span, class: label_class.join(' ')) do
            append.dig(:label).to_s.html_safe
          end
        end
      end
    end

    appends
  end

  def input_field_prepends(prepend_array)
    prepends = ''

    [prepend_array || []].flatten.each_with_index do |prepend, index|
      prepends += content_tag(:div, class: 'input-group-prepend') do
        if prepend.dig(:button).to_bool
          label_class = %w[input-group-text bg-info border-info text-light pr-2]
          label_class << prepend[:label_class].to_s if prepend.dig(:label_class).to_s.present?
          button_tag((prepend.dig(:label) || 'Submit').to_s.html_safe, { id: prepend.dig(:id).to_s, class: label_class.join(' '), style: prepend.dig(:display).nil? || prepend[:display].to_bool ? '' : 'display:none;', disabled: prepend.dig(:disabled).to_bool, onclick: prepend.dig(:onclick).to_s })
        else
          label_class = ['input-group-text']
          label_class << prepend[:label_class].to_s if prepend.dig(:label_class).to_s.present?
          content_tag(:span, class: label_class.join(' ')) do
            prepend.dig(:label).to_s.html_safe
          end
        end
      end
    end

    prepends
  end

  def label_string(label, note, required)
    if note.to_s.present?
      "#{label.to_s.capitalize}#{required ? '<i class="bi bi-superscript">*</i>' : ''} <i class=\"fa fa-question-circle\" data-toggle=\"tooltip\" data-html=true data-container=\"body\" title=\"#{note}\"></i>"
    else
      "#{label.to_s.capitalize}#{required ? '<i class="bi bi-superscript">*</i>' : ''}"
    end
  end

  def label_class(label_class, columns)
    ["col-md-#{columns[0]}", label_class, label_class.split.grep(%r{^m-}).any? || label_class.split.grep(%r{^mt-}).any? ? '' : 'mt-0'].reject(&:empty?).join(' ')
  end

  def select_script(id)
    '$(function () {' \
      "var element = $('##{id}');" \
      "var parent_element = $('##{id}').parent().children()[0];" \
      'element.detach();' \
      'parent_element.append(element[0]);' \
      '});'
  end

  def typeahead_script(id, client, drop_up)
    # provide #hashtag variable selector to name
    ActionController::Base.helpers.sanitize("MultiTypeahead('##{id}', #{options_for_hashtag(client:).to_json.html_safe}, '#', #{drop_up});")
  end

  # rubocop:enable Rails/OutputSafety
end
