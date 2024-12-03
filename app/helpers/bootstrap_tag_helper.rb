# frozen_string_literal: true

# app/helpers/bootstrap_tag_helper.rb
# rubocop:disable Rails/OutputSafety
module BootstrapTagHelper
  # <%= bootstrap_calendar_field(
  #   field: 'string',
  #   value: 'string',
  #   modal: { id: 'string' },
  #   row: { class: 'string', id: 'string', display: boolean, columns: [l, r] },
  #   col: { class: 'string', id: 'string', display: boolean },
  #   form_group: { class: 'string', id: 'string', display: boolean },
  #   label: { class: 'string', id: 'string', title: 'string' },
  #   html_options: { class: 'string', id: 'string', placeholder: 'string', required: boolean, disabled: boolean, autofocus: boolean },
  #   flatpickr: { include_time: boolean, mode: 'single/multiple/range', min_date: 'string', max_date: 'string, on_change: function },
  #   google_calendar: { calendar_ids: Array, title: String, description: String, location: String, recurrence: String, attendee_emails: Array },
  #   messages: { note: 'string' }
  # ) % >
  def bootstrap_calendar_field(args = {})
    html_options      = html_options(args.dig(:html_options))
    html_options[:id] = "calendar_field_#{rand(1000)}" if html_options[:id].blank?
    columns           = columns(args.dig(:row, :columns))
    col_class         = col_class(args.dig(:col, :class).to_s, columns)
    label_class       = label_class(args.dig(:label, :class).to_s, columns)
    links             = ''

    (args.dig(:google_calendar, :calendar_ids) || []).each do |calendar_name, calendar_id|
      links += link_to(calendar_name,
                       '#',
                       class: %w[dropdown-item] << "google_calendar_array_#{html_options[:id]}",
                       style: 'text-decoration: none;',
                       data:  { calendar_name:, calendar_id: })
    end

    response = content_tag(:div, class: form_row_class(args.dig(:row, :class)), id: args.dig(:row, :id).to_s, style: (args.dig(:row, :display).nil? || args[:row][:display].to_bool ? '' : 'display:none;').to_s) do
      content_tag(:label, label_string(args.dig(:label, :title), args.dig(:messages, :note), args.dig(:html_options, :required).to_bool).html_safe, for: html_options[:id], class: label_class, id: args.dig(:label, :id).to_s) +
        content_tag(:div, class: col_class, id: args.dig(:col, :id).to_s, style: (args.dig(:col, :display).nil? || args.dig(:col, :display).to_bool ? '' : 'display:none;').to_s) do
          content_tag(:div, class: (%w[form-group] + args.dig(:form_group, :class).to_s.split).join(' '), id: args.dig(:form_group, :id).to_s, style: (args.dig(:form_group, :display).nil? || args.dig(:form_group, :display).to_bool ? '' : 'display:none;').to_s) do
            content_tag(:div, class: %w[input-group input-group-alt flatpickr flex-wrap]) do
              content_tag(:div, class: %w[input-group-prepend]) do
                button_tag('', { class: %w[input-group-text fa fa-calendar], title: 'toggle', id: "button_calendar_open_#{html_options[:id]}", type: 'button' }) +
                  button_tag('', { class: %w[input-group-text fa fa-times], id: "button_calendar_clear_#{html_options[:id]}", type: 'button' }) +
                  if args.dig(:google_calendar, :calendar_ids).present?
                    button_tag('', { class: %w[input-group-text fab fa-google], id: "button_calendar_google_#{html_options[:id]}", type: 'button', data: { toggle: 'dropdown' } }) +
                    content_tag(:div, class: %w[dropdown-menu dropdown-menu-right]) do
                      content_tag(:div, class: %w[dropdown-arrow]) { '' } +
                        content_tag(:h6, class: %w[dropdown-header stop-propagation]) do
                          content_tag(:span, 'Select a Google Calendar')
                        end +
                        content_tag(:div, class: %w[dropdown-divider]) { '' } +
                        links.html_safe
                    end
                  end
              end +
                text_field_tag(args.dig(:field).to_sym, args.dig(:value).to_s, html_options)
            end
          end
        end
    end

    response += content_tag(:script, calendar_script(id: html_options[:id], model_id: args.dig(:modal, :id), value: args.dig(:value), flatpickr: args.dig(:flatpickr), google_calendar: args.dig(:google_calendar) || {}))

    response
  end

  # <%= bootstrap_check_box(
  #   row: { class: 'string', id: 'string', display: boolean, columns: [l, r] },
  #   col: { class: 'string', id: 'string', display: boolean },
  #   label: { class: 'string', id: 'string', title: 'string' },
  #   checkboxes: [{ field: 'string', label: 'string', class: 'string', id: 'string', checked: true/false, values: [on, off] }, ...],
  #   messages: { note: 'string' }
  # ) %>
  def bootstrap_check_box(args = {})
    columns             = columns(args.dig(:row, :columns))
    checkboxes          = ''
    html_option_classes = %w[custom-control-input]

    args.dig(:checkboxes).each do |checkbox|
      html_options = {}
      html_options[:class]   = html_option_classes + checkbox.dig(:class).to_s.split
      html_options[:id]      = (checkbox.dig(:id) || "checkbox_#{rand(100_000)}").to_s
      html_options[:checked] = checkbox[:checked].to_bool unless checkbox.dig(:checked).nil?
      values = [checkbox.dig(:values) || [true, false]].flatten
      values = values.length == 1 ? [values[0], false] : [true, false] unless values.length == 2
      checkboxes += content_tag(:div, class: %w[custom-control custom-checkbox]) do
        hidden_field_tag(checkbox.dig(:field).to_s, values[1]) +
          check_box_tag(checkbox.dig(:field).to_s, values[0], checkbox.dig(:value), html_options) +
          label_tag(html_options[:id], checkbox.dig(:label).to_s, { class: %w[custom-control-label] })
      end
    end

    content_tag(:div, class: form_row_class(args.dig(:row, :class)), id: args.dig(:row, :id).to_s, style: (args.dig(:row, :display).nil? || args[:row][:display].to_bool ? '' : 'display:none;').to_s) do
      content_tag(:label, label_string(args.dig(:label, :title), args.dig(:messages, :note), args.dig(:html_options, :required).to_bool).html_safe, class: label_class(args.dig(:label, :class).to_s, columns), id: args.dig(:label, :id).to_s) +
        content_tag(:div, class: col_class(args.dig(:col, :class).to_s, columns), id: args.dig(:col, :id).to_s, style: (args.dig(:col, :display).nil? || args.dig(:col, :display).to_bool ? '' : 'display:none;').to_s) do
          checkboxes.html_safe
        end
    end
  end

  # <%= bootstrap_color_picker(
  #   field: 'string',
  #   value: 'string',
  #   row: { class: 'string', id: 'string', display: boolean, columns: [l, r] },
  #   col: { class: 'string', id: 'string', display: boolean },
  #   form_group: { class: 'string', id: 'string', display: boolean },
  #   label: { class: 'string', id: 'string', title: 'string' },
  #   html_options: { class: 'string', id: 'string', placeholder: 'string', required: boolean, disabled: boolean, autofocus: boolean },
  #   appends: [{ button: boolean, label: 'string', id: 'string', display: boolean, disabled: boolean }, ...],
  #   messages: { note: 'string' }
  # ) %>
  def bootstrap_color_picker(args = {})
    html_options = html_options(args.dig(:html_options))
    columns      = columns(args.dig(:row, :columns))
    col_class    = col_class(args.dig(:col, :class).to_s, columns)
    label_class  = label_class(args.dig(:label, :class).to_s, columns)
    appends      = input_field_appends([{ button: false, label: '<i class="align-self-center"></i>', label_class: 'colorpicker-input-addon' }])

    content_tag(:div, class: form_row_class(args.dig(:row, :class)), id: args.dig(:row, :id).to_s, style: (args.dig(:row, :display).nil? || args[:row][:display].to_bool ? '' : 'display:none;').to_s) do
      content_tag(:label, label_string(args.dig(:label, :title), args.dig(:messages, :note), args.dig(:html_options, :required).to_bool).html_safe, for: html_options[:id], class: label_class, id: args.dig(:label, :id).to_s) +
        content_tag(:div, class: col_class, id: args.dig(:col, :id).to_s, style: (args.dig(:col, :display).nil? || args.dig(:col, :display).to_bool ? '' : 'display:none;').to_s) do
          content_tag(:div, class: (%w[form-group] + args.dig(:form_group, :class).to_s.split).join(' '), id: args.dig(:form_group, :id).to_s, style: (args.dig(:form_group, :display).nil? || args.dig(:form_group, :display).to_bool ? '' : 'display:none;').to_s) do
            content_tag(:div, class: %w[input-group input-group-alt flex-wrap], 'data-toggle': 'colorpicker', 'data-format': 'hex', 'data-use-alpha': 'true') do
              text_field_tag(args.dig(:field).to_sym, args.dig(:value).to_s, html_options) +
                appends.html_safe
            end
          end
        end
    end
  end

  # <%= bootstrap_copy_field(
  #   field: 'string',
  #   value: 'string',
  #   row: { class: 'string', id: 'string', display: boolean, columns: [l, r] },
  #   col: { class: 'string', id: 'string', display: boolean },
  #   form_group: { class: 'string', id: 'string', display: boolean },
  #   input_group: { class: 'string' },
  #   label: { class: 'string', id: 'string', title: 'string' },
  #   html_options: { class: 'string', id: 'string', placeholder: 'string', minlength: integer, maxlength: integer, size: integer, typeahead_client: Client, type: string, required: boolean, disabled: boolean, autofocus: boolean },
  #   prepends: [{ button: boolean, label: 'string', id: 'string', display: boolean, disabled: boolean }, ...],
  #   appends: [{ button: boolean, label: 'string', id: 'string', display: boolean, disabled: boolean, onclick: 'string' }, ...],
  #   messages: { note: 'string' },
  # ) %>
  def bootstrap_copy_field(args = {})
    unique_id                      = rand(100_000)
    args[:field]                   = args.dig(:field).presence || "copy_field_#{unique_id}"
    args[:html_options]            = {} unless args.dig(:html_options)
    args[:html_options][:id]       = "copy_field_#{unique_id}" unless args.dig(:html_options, :id)
    args[:html_options][:disabled] = true
    args[:appends]                 = [{ button: true, label: '<i class="fa fa-clipboard"></i>'.html_safe, id: "copy_button_#{unique_id}", onclick: "event.preventDefault();copyToClipboard('#{args[:html_options][:id]}');" }]
    bootstrap_text_field(**args)
  end

  # <%= bootstrap_email_field(
  #   field: 'string',
  #   value: 'string',
  #   row: { class: 'string', id: 'string', display: boolean, columns: [l, r] },
  #   col: { class: 'string', id: 'string', display: boolean },
  #   form_group: { class: 'string', id: 'string', display: boolean },
  #   input_group: { class: 'string' },
  #   label: { class: 'string', id: 'string', title: 'string' },
  #   html_options: { value: 'string', class: 'string', id: 'string', placeholder: 'string', minlength: integer, maxlength: integer, size: integer, typeahead_client: Client, typeahead_drop_up: boolean, required: boolean, disabled: boolean, autofocus: boolean },
  #   prepends: [{ button: boolean, label: 'string', id: 'string', display: boolean, disabled: boolean }, ...],
  #   appends: [{ button: boolean, label: 'string', id: 'string', display: boolean, disabled: boolean }, ...],
  #   messages: { note: 'string' }
  # ) %>
  def bootstrap_email_field(args = {})
    html_options = html_options(args.dig(:html_options))
    columns      = columns(args.dig(:row, :columns))
    col_class    = col_class(args.dig(:col, :class).to_s, columns)
    label_class  = label_class(args.dig(:label, :class).to_s, columns)
    prepends     = input_field_prepends(args.dig(:prepends) || [{ button: false, label: '<i class="fa fa-envelope"></i>' }])
    appends      = input_field_appends(args.dig(:appends))

    response = content_tag(:div, class: form_row_class(args.dig(:row, :class)), id: args.dig(:row, :id).to_s, style: (args.dig(:row, :display).nil? || args[:row][:display].to_bool ? '' : 'display:none;').to_s) do
      content_tag(:label, label_string(args.dig(:label, :title), args.dig(:messages, :note), args.dig(:html_options, :required).to_bool).html_safe, for: html_options[:id], class: label_class, id: args.dig(:label, :id).to_s) +
        content_tag(:div, class: col_class, id: args.dig(:col, :id).to_s, style: (args.dig(:col, :display).nil? || args.dig(:col, :display).to_bool ? '' : 'display:none;').to_s) do
          content_tag(:div, class: (%w[form-group] + args.dig(:form_group, :class).to_s.split).join(' '), id: args.dig(:form_group, :id).to_s, style: (args.dig(:form_group, :display).nil? || args.dig(:form_group, :display).to_bool ? '' : 'display:none;').to_s) do
            content_tag(:div, class: (%w[input-group has-typeahead-scrollable flex-wrap] + (appends.present? ? %w[input-group-alt] : []) + args.dig(:input_group, :class).to_s.split)) do
              prepends.html_safe +
                email_field_tag(args.dig(:field).to_sym, args.dig(:value).to_s, html_options) +
                appends.html_safe
            end
          end
        end
    end

    response += content_tag(:script, typeahead_script(html_options[:id], args[:html_options][:typeahead_client], args[:html_options][:typeahead_drop_up].to_bool)) if args.dig(:html_options, :typeahead_client).is_a?(Client)

    response
  end

  # <%= bootstrap_file_field'(
  #   file_field: { field: 'string', id: 'string', name: 'string', url: 'string', disabled: boolean, accepted_files: array },
  #   row: { class: 'string', id: 'string', display: boolean, columns: [l, r] },
  #   col: { class: 'string', id: 'string', display: boolean },
  #   label: { class: 'string', id: 'string', title: 'string' },
  #   image_container: { class: 'string', id: 'string' },
  #   image: { key: 'string', width: integer, height: integer, class: 'string', crop: 'fit', format: 'png' },
  #   javascript: 'string'
  # ) %>
  def bootstrap_file_field(args = {})
    accepted_files           = args.dig(:file_field, :accepted_files)
    columns                  = columns(args.dig(:row, :columns))
    col_class                = col_class(args.dig(:col, :class).to_s, columns) + (args.dig(:file_field, :disabled).to_bool ? [] : %w[fileinput-dropzone])
    label_class              = label_class(args.dig(:label, :class).to_s, columns)
    transformations          = {}
    transformations[:width]  = args[:image][:width].to_i if args.dig(:image, :width)
    transformations[:height] = args[:image][:height].to_i if args.dig(:image, :height)
    transformations[:crop]   = args[:image][:crop].to_s if args.dig(:image, :crop)
    figure_style             = if transformations.dig(:width).to_i.positive? || transformations.dig(:height).to_i.positive?
                                 "#{transformations.dig(:width).to_i.positive? ? "width:#{transformations.dig(:width).to_i}px;" : ''}#{transformations.dig(:height).to_i.positive? ? "height:#{transformations.dig(:height).to_i}px;" : ''}"
                               else
                                 ''
                               end
    drop_zone_id             = (args.dig(:col, :id) || "drop_zone_#{rand(1000)}").to_s
    file_field_id            = (args.dig(:file_field, :id) || "file_field_#{rand(1000)}").to_s
    image_container_id       = (args.dig(:image_container, :id) || "image_container_#{rand(1000)}").to_s
    javascript               = args.include?(:javascript) ? args.dig(:javascript) : true

    image_upload_area = if args.dig(:image).present?
                          content_tag(:figure, class: %w[user-avatar user-avatar-xxl], style: figure_style) do
                            cl_image_tag(args.dig(:image, :key).to_s, { class: args.dig(:image, :class).to_s, secure_distribution: I18n.t("tenant.#{Rails.env}.cloudinary_cname"), transformation: transformations, format: (args.dig(:image, :format) || 'fit').to_s }) +
                              link_to(content_tag(:i, '', class: %w[fa fa-times]), '#', class: %w[avatar-badge has-indicator busy], style: 'height:20px;width:20px;border-radius:10px;line-height:21px;font-size:15px;color:white;', id: "button_image_delete_#{image_container_id}")
                          end
                        elsif args.dig(:file_field, :disabled).to_bool
                          ''
                        else
                          content_tag(:i, '', class: %w[fa fa-cloud-upload-alt text-primary display-3])
                        end

    drag_drop_string = if args.dig(:file_field, :disabled).to_bool
                         ''
                       else
                         content_tag(:span, class: %w[text-muted]) { 'Drag and drop or Click to Upload' }
                       end

    content_tag(:div, class: form_row_class(args.dig(:row, :class)), id: args.dig(:row, :id).to_s, style: (args.dig(:row, :display).nil? || args[:row][:display].to_bool ? '' : 'display:none;').to_s) do
      content_tag(:label, args.dig(:label, :title).to_s, for: file_field_id, class: label_class, id: args.dig(:label, :id).to_s) +
        file_field_tag(file_field_id, value: args.dig(:file_field, :field).to_sym, name: args.dig(:file_field, :name).to_s, class: %w[image-url form-control], id: file_field_id, direct_upload: true, style: 'display:none;') +
        content_tag(:div, class: col_class, id: drop_zone_id, style: (args.dig(:col, :display).nil? || args.dig(:col, :display).to_bool ? '' : 'display:none;').to_s) do
          content_tag(:div, class: %w[text-center] << args.dig(:image_container, :class), id: image_container_id) do
            image_upload_area.html_safe
          end +
            content_tag(:div, class: %w[spinner-border text-primary d-none], id: "spinner_#{image_container_id}", role: 'status') do
              content_tag(:span, class: %w[sr-only]) { 'Loading...' }
            end +
            drag_drop_string.html_safe
        end
    end +
      dropzone_script(
        drop_zone_id:,
        file_field_id:,
        image_container_id:,
        accepted_files:,
        javascript:,
        name:               args.dig(:file_field, :name).to_s,
        url:                args.dig(:file_field, :url).to_s,
        disabled:           args.dig(:file_field, :disabled).to_bool
      ).html_safe
  end

  # <%= bootstrap_info_field(
  #   info: 'string',
  #   info_wrapper: { tag: 'string', class: 'string', id: 'string' },
  #   row: { class: 'string', id: 'string', display: boolean, columns: [l, r] },
  #   col: { class: 'string', id: 'string', display: boolean },
  #   label: { class: 'string', id: 'string', title: 'string' },
  #   html_options: { class: 'string', id: 'string' },
  #   messages: { note: 'string' }
  # ) %>
  def bootstrap_info_field(args = {})
    columns      = columns(args.dig(:row, :columns))
    col_class    = col_class((args.dig(:col, :class).to_s.split.grep(%r{^m-}).any? || args.dig(:col, :class).to_s.split.grep(%r{^mt-}).any? ? args.dig(:col, :class).to_s.split : args.dig(:col, :class).to_s.split << 'mt-0').reject(&:empty?).join(' '), columns)
    label_class  = label_class(args.dig(:label, :class).to_s, columns)

    content_tag(:div, class: form_row_class(args.dig(:row, :class)), id: args.dig(:row, :id).to_s, style: (args.dig(:row, :display).nil? || args[:row][:display].to_bool ? '' : 'display:none;').to_s) do
      content_tag(:label, label_string(args.dig(:label, :title), args.dig(:messages, :note), false).html_safe, class: label_class, id: args.dig(:label, :id).to_s) +
        content_tag(:div, class: col_class, id: args.dig(:col, :id).to_s, style: (args.dig(:col, :display).nil? || args.dig(:col, :display).to_bool ? '' : 'display:none;').to_s) do
          content_tag(:span, class: args.dig(:html_options, :class).to_s, id: args.dig(:html_options, :id).to_s) do
            simple_format(args.dig(:info).to_s, args.dig(:info_wrapper)&.except(:tag) || {}, { wrapper_tag: args.dig(:info_wrapper, :tag) || 'p' }).html_safe
          end
        end
    end
  end

  # <%= bootstrap_number_field(
  #   field: 'string',
  #   value: 'integer/float/decimal',
  #   row: { class: 'string', id: 'string', display: boolean, columns: [l, r] },
  #   col: { class: 'string', id: 'string', display: boolean },
  #   form_group: { class: 'string', id: 'string', display: boolean },
  #   label: { class: 'string', id: 'string', title: 'string' },
  #   html_options: { value: 'integer/decimal', class: 'string', id: 'string', min: integer/float/decimal, max: integer/float/decimal, step: integer/float/decimal, required: boolean, disabled: boolean, autofocus: boolean },
  #   prepends: [{ button: boolean, label: 'string', id: 'string', display: boolean, disabled: boolean }, ...],
  #   appends: [{ button: boolean, label: 'string', id: 'string', display: boolean, disabled: boolean }, ...],
  #   messages: { note: 'string' }
  # ) %>
  def bootstrap_number_field(args = {})
    html_options = html_options(args.dig(:html_options))
    columns      = columns(args.dig(:row, :columns))
    col_class    = col_class(args.dig(:col, :class).to_s, columns)
    label_class  = label_class(args.dig(:label, :class).to_s, columns)
    prepends     = input_field_prepends(args.dig(:prepends) || [{ button: false, label: '<i class="fa fa-hashtag"></i>' }])
    appends      = input_field_appends(args.dig(:appends))

    response = content_tag(:div, class: form_row_class(args.dig(:row, :class)), id: args.dig(:row, :id).to_s, style: (args.dig(:row, :display).nil? || args[:row][:display].to_bool ? '' : 'display:none;').to_s) do
      content_tag(:label, label_string(args.dig(:label, :title), args.dig(:messages, :note), args.dig(:html_options, :required).to_bool).html_safe, class: label_class, id: args.dig(:label, :id).to_s) +
        content_tag(:div, class: col_class, id: args.dig(:col, :id).to_s, style: (args.dig(:col, :display).nil? || args.dig(:col, :display).to_bool ? '' : 'display:none;').to_s) do
          content_tag(:div, class: (%w[form-group flex-wrap] + args.dig(:form_group, :class).to_s.split).join(' '), id: args.dig(:form_group, :id).to_s, style: (args.dig(:form_group, :display).nil? || args.dig(:form_group, :display).to_bool ? '' : 'display:none;').to_s) do
            content_tag(:div, class: (%w[input-group has-typeahead-scrollable flex-wrap] + (appends.present? ? %w[input-group-alt] : []))) do
              prepends.html_safe +
                number_field_tag(args.dig(:field).to_s, args.dig(:value).to_s, html_options) +
                appends.html_safe
            end
          end
        end
    end

    response += content_tag(:script, typeahead_script(html_options[:id], args[:html_options][:typeahead_client], args[:html_options][:typeahead_drop_up].to_bool)) if args.dig(:html_options, :typeahead_client).is_a?(Client)

    response
  end

  # <%= bootstrap_range_slider(
  #   field: 'string',
  #   row: { class: 'string', id: 'string', display: boolean, columns: [l, r] },
  #   col: { class: 'string', id: 'string', display: boolean },
  #   form_group: { class: 'string', id: 'string', display: boolean },
  #   label: { class: 'string', id: 'string', title: 'string' },
  #   html_options: { class: 'string', id: 'string', required: boolean, autofocus: boolean },
  #   range_slider: { id: 'string', type: 'single/double', min: integer, max: integer, from: integer, to: integer, step: integer, grid: boolean, grid_num: integer, prefix: '$', separator: ',', postfix: 'string', disabled: boolean },
  #   messages: { note: 'string' }
  # ) %>
  def bootstrap_range_slider(args = {})
    html_options      = html_options(args.dig(:html_options))
    html_options[:id] = "rangeslider_#{rand(1000)}" if html_options[:id].blank?
    columns           = columns(args.dig(:row, :columns))
    col_class         = col_class(args.dig(:col, :class).to_s, columns)
    label_class       = label_class(args.dig(:label, :class).to_s, columns)

    response = content_tag(:div, class: form_row_class(args.dig(:row, :class)), id: args.dig(:row, :id).to_s, style: (args.dig(:row, :display).nil? || args[:row][:display].to_bool ? '' : 'display:none;').to_s) do
      content_tag(:label, label_string(args.dig(:label, :title), args.dig(:messages, :note), args.dig(:html_options, :required).to_bool).html_safe, class: label_class, id: args.dig(:label, :id).to_s) +
        content_tag(:div, class: col_class, id: args.dig(:col, :id).to_s, style: (args.dig(:col, :display).nil? || args.dig(:col, :display).to_bool ? '' : 'display:none;').to_s) do
          content_tag(:div, class: (%w[form-group] + args.dig(:form_group, :class).to_s.split).join(' '), id: args.dig(:form_group, :id).to_s, style: (args.dig(:form_group, :display).nil? || args.dig(:form_group, :display).to_bool ? '' : 'display:none;').to_s) do
            text_field_tag(args.dig(:field).to_sym, '', html_options)
          end
        end
    end

    response += content_tag(:script, range_slider_script(id: html_options[:id], range_slider: args.dig(:range_slider)))

    response
  end

  # <%= bootstrap_select_tag(
  #   field: 'string',
  #   row: { class: 'string', id: 'string', display: boolean, columns: [l, r] },
  #   col: { class: 'string', id: 'string', display: boolean },
  #   form_group: { class: 'string', id: 'string', display: boolean },
  #   label: { class: 'string', id: 'string', title: 'string' },
  #   html_options: { class: 'string', id: 'string', data: Hash, required: boolean, disabled: boolean, multi_actions: boolean, multiple: boolean, autofocus: boolean, sp_size: integer, maxoptions: integer, count_selected_text: 'string' },
  #   options: { for_select: options, array: array, grouped_array: array, selected: 'string/integer', blank: 'string', prompt: 'string', live_search: boolean, dynamic: boolean, lookup: { url: String, client: Client }, left_border: string },
  #   prepends: [{ button: boolean, label: 'string', id: 'string', display: boolean, disabled: boolean }, ...],
  #   appends: [{ button: boolean, label: 'string', id: 'string', display: boolean, disabled: boolean }, ...],
  #   messages: { note: 'string' }
  # ) %>
  def bootstrap_select_tag(args = {})
    html_options            = html_options((args.dig(:html_options) || {}).merge(live_search: args.dig(:options, :live_search), select: true))
    columns                 = columns(args.dig(:row, :columns))
    col_class               = col_class(args.dig(:col, :class).to_s, columns)
    label_class             = label_class(args.dig(:label, :class).to_s, columns)
    left_border             = args.dig(:options).include?(:left_border) ? args.dig(:options, :left_border) : false
    prepends                = input_field_prepends(args.dig(:prepends))
    appends                 = input_field_appends(args.dig(:appends))
    options_for_select      = args.dig(:options, :for_select) unless args.dig(:options, :for_select).nil?
    options_for_select      = options_for_select(args.dig(:options, :array), args.dig(:options, :selected)) unless args.dig(:options, :array).nil?
    options_for_select      = grouped_options_for_select(args.dig(:options, :grouped_array), args.dig(:options, :selected)) unless args.dig(:options, :grouped_array).nil?

    additional_options                 = {}
    additional_options[:include_blank] = args[:options][:blank] unless args.dig(:options, :blank).nil?
    additional_options[:prompt]        = args[:options][:prompt] unless args.dig(:options, :prompt).nil?

    input_group_class = %w[input-group no-left-border flex-wrap]
    input_group_class.delete('no-left-border') if left_border

    response = content_tag(:div, class: form_row_class(args.dig(:row, :class)), id: args.dig(:row, :id).to_s, style: (args.dig(:row, :display).nil? || args[:row][:display].to_bool ? '' : 'display:none;').to_s) do
      content_tag(:label, label_string(args.dig(:label, :title), args.dig(:messages, :note), args.dig(:html_options, :required).to_bool).html_safe, for: html_options[:id], class: label_class, id: args.dig(:label, :id).to_s) +
        content_tag(:div, class: col_class, id: args.dig(:col, :id).to_s, style: (args.dig(:col, :display).nil? || args.dig(:col, :display).to_bool ? '' : 'display:none;').to_s) do
          content_tag(:div, class: (%w[form-group] + args.dig(:form_group, :class).to_s.split).join(' '), id: args.dig(:form_group, :id).to_s, style: (args.dig(:form_group, :display).nil? || args.dig(:form_group, :display).to_bool ? '' : 'display:none;').to_s) do
            content_tag(:div, class: (input_group_class + (appends.present? ? %w[input-group-alt] : []))) do
              prepends.html_safe +
                select('', args.dig(:field).to_sym, options_for_select, additional_options, html_options) +
                appends.html_safe
            end
          end
        end
    end

    response += content_tag(:script, dynamic_options_for_select_script(id: html_options[:id]).html_safe) if args.dig(:options, :dynamic).to_bool
    response += content_tag(:script, lookup_for_select_script(id: html_options[:id], lookup_url: args.dig(:options, :lookup, :url), lookup_client_id: args.dig(:options, :lookup, :client).id)) if args.dig(:options, :lookup, :url).present? && args.dig(:options, :lookup, :client).present?

    response
  end

  # <%= bootstrap_select_tag_campaign(
  #   client: Client,
  #   field: 'string',
  #   row: { class: 'string', id: 'string', display: Boolean, columns: [l, r] },
  #   col: { class: 'string', id: 'string', display: Boolean },
  #   form_group: { class: 'string', id: 'string', display: Boolean },
  #   label: { class: 'string', id: 'string', title: 'string' },
  #   html_options: { class: 'string', id: 'string', data: Hash, required: Boolean, disabled: Boolean, multiple: Boolean, autofocus: Boolean },
  #   options: { exclude_campaigns: Array, first_trigger_types: Array, selected: 'string/integer', append: Array, include_groups: Boolean, active_only: Boolean, blank: 'string' },
  #   prepends: [{ button: boolean, label: 'string', id: 'string', display: boolean, disabled: boolean }, ...],
  #   appends: [{ button: boolean, label: 'string', id: 'string', display: boolean, disabled: boolean }, ...],
  #   help: { header: 'string', bullets: Array },
  #   messages: { note: 'string' }
  # ) %>
  def bootstrap_select_tag_campaign(args = {})
    exclude_campaigns                      = [args.dig(:options, :exclude_campaigns) || []].flatten
    first_trigger_types                    = [args.dig(:options, :first_trigger_types) || []].flatten
    campaign_options                       = { client: args.dig(:client), selected_campaign_id: args.dig(:options, :selected), add_options: args.dig(:options, :append) || [], include_groups: args.dig(:options, :include_groups).to_bool, active_only: args.dig(:options, :active_only).to_bool, grouped: true }
    campaign_options[:exclude_campaigns]   = exclude_campaigns if exclude_campaigns.present?
    campaign_options[:first_trigger_types] = first_trigger_types if first_trigger_types.present?

    options                                = args.dig(:options) || {}
    options[:blank]                      ||= 'Select a Campaign'
    options[:for_select]                   = options_for_campaign(campaign_options)

    if args.dig(:client).is_a?(Client)
      response = bootstrap_select_tag(
        field:        args.dig(:field),
        row:          args.dig(:row),
        col:          args.dig(:col),
        form_group:   args.dig(:form_group),
        label:        args.dig(:label),
        html_options: args.dig(:html_options),
        options:,
        prepends:     args.dig(:prepends),
        messages:     args.dig(:messages)
      )

      if args.dig(:help)
        bullets = ''

        (args.dig(:help, :bullets) || []).each do |bullet|
          bullets += content_tag(:li) do
            content_tag(:span, class: %w[fa-li]) do
              content_tag(:i, '', class: %w[fa fa-check text-success])
            end + bullet
          end
        end

        response += content_tag(:div, class: %w[form-group mt-3 ml-5 mr-5 pl-2 pr-2]) do
          content_tag(:small, class: %w[text-muted]) do
            args.dig(:help, :header).to_s.html_safe +
              content_tag(:ul, class: %w[fa-ul]) do
                bullets.html_safe
              end
          end
        end
      end
    end

    response
  end

  # <%= bootstrap_spinning_logo(
  #   style:   'max-height:60px;','
  #   message: 'Loading'
  # ) %>
  def bootstrap_spinning_logo(args = {})
    tag.div(class: 'w100 text-center') do
      image_tag("tenant/#{I18n.t('tenant.id')}/logo.svg", class: 'spinning-logo', style: args.dig(:style).to_s) +
        tag.div(class: 'ml-3 pb-3') do
          "#{args.dig(:message) || 'Loading'}..."
        end
    end
  end

  # <%= bootstrap_submit_buttons(
  #   row: { class: 'string', id: 'string', display: boolean },
  #   buttons: [{ title: 'string', class: 'string', id: 'string', disable_with: 'string', disabled: boolean, display: boolean }, ...]
  # ) %>
  def bootstrap_submit_buttons(args = {})
    buttons      = ''
    button_class = %w[btn btn-info mb-1 mb-md-0]

    args.dig(:buttons).each do |button|
      buttons += submit_tag((button.dig(:title) || 'Submit').to_s, { class: button_class + button.dig(:class).to_s.split, id: button.dig(:id), disabled: button.dig(:disabled).to_bool, data: { disable_with: "#{button.dig(:disable_with) || 'Submitting'}...", turbo_submits_with: "#{button.dig(:disable_with) || 'Submitting'}..." }, style: (button.dig(:display).nil? || button.dig(:display).to_bool ? '' : 'display:none;').to_s })
    end

    content_tag(:div, class: %w[mt-auto] + args.dig(:row, :class).to_s.split, id: args.dig(:row, :id).to_s, style: (args.dig(:row, :display).nil? || args[:row][:display].to_bool ? '' : 'display:none;').to_s) do
      content_tag(:div, class: %w[form-actions d-flex flex-column flex-md-row justify-content-end]) do
        buttons.html_safe
      end
    end
  end

  # <%= bootstrap_switch_field(
  #   field: 'string',
  #   value: 'string',
  #   values: [on, off],
  #   row: { class: 'string', id: 'string', display: boolean, columns: [l, r] },
  #   col: { class: 'string', id: 'string', display: boolean },
  #   form_group: { class: 'string', id: 'string', display: boolean, hidden_field: boolean },
  #   label: { class: 'string', id: 'string', title: 'string', checked: 'string', unchecked: 'string' },
  #   html_options: { class: 'string', id: 'string', required: boolean, disabled: boolean, autofocus: boolean },
  #   messages: { note: 'string' }
  # ) %>
  def bootstrap_switch_field(args = {})
    html_options = html_options(args.dig(:html_options))
    html_options[:class] = (html_options[:class].split - %w[form-control typeahead] + %w[switcher-input]).join(' ')
    columns      = columns(args.dig(:row, :columns))
    # col_class    = col_class((args.dig(:col, :class).to_s.split << 'mb-3').join(' '), columns)
    col_class    = col_class(args.dig(:col, :class).to_s, columns)
    label_class  = label_class(args.dig(:label, :class).to_s, columns)
    values       = [args[:values] || [true, false]].flatten
    values       = values.length == 1 ? [values[0], false] : [true, false] unless values.length == 2
    hidden_field = args.dig(:form_group, :hidden_field).nil? || args[:form_group][:hidden_field].to_bool ? hidden_field_tag(args.dig(:field).to_s, values[1]) : ''

    content_tag(:div, class: form_row_class(args.dig(:row, :class)), id: args.dig(:row, :id).to_s, style: (args.dig(:row, :display).nil? || args[:row][:display].to_bool ? '' : 'display:none;').to_s) do
      label_tag(args.dig(:html_options, :id).to_s, label_string(args.dig(:label, :title), args.dig(:messages, :note), args.dig(:html_options, :required).to_bool).html_safe, { class: label_class, id: args.dig(:label, :id).to_s }) +
        content_tag(:div, class: col_class, id: args.dig(:col, :id).to_s, style: (args.dig(:col, :display).nil? || args.dig(:col, :display).to_bool ? '' : 'display:none;').to_s) do
          content_tag(:div, class: (%w[list-group-item d-flex align-items-center p-0 bg-transparent] + args.dig(:form_group, :class).to_s.split).join(' '), id: args.dig(:form_group, :id).to_s, style: (args.dig(:form_group, :display).nil? || args.dig(:form_group, :display).to_bool ? '' : 'display:none;').to_s) do
            content_tag(:label, class: %w[switcher-control switcher-control-lg], style: 'cursor:pointer;') do
              hidden_field.html_safe +
                check_box_tag(args.dig(:field).to_s, values[0], args.dig(:value), html_options) +
                content_tag(:span, class: %w[switcher-indicator]) { '' } +
                content_tag(:span, class: %w[switcher-label-on]) do
                  (args.dig(:label, :checked) || '<i class="fa fa-check"></i>').to_s.html_safe
                end +
                content_tag(:span, class: %w[switcher-label-off]) do
                  (args.dig(:label, :unchecked) || '<i class="fa fa-times"></i>').to_s.html_safe
                end
            end
          end
        end
    end
  end

  # <%= bootstrap_telephone_field(
  #   field: 'string',
  #   value: 'string',
  #   row: { class: 'string', id: 'string', display: boolean, columns: [l, r] },
  #   col: { class: 'string', id: 'string', display: boolean },
  #   form_group: { class: 'string', id: 'string', display: boolean },
  #   label: { class: 'string', id: 'string', title: 'string' },
  #   html_options: { value: 'string', class: 'string', id: 'string', placeholder: 'string', size: integer, required: boolean, disabled: boolean, autofocus: boolean },
  #   prepends: [{ button: boolean, label: 'string', id: 'string', display: boolean, disabled: boolean }, ...],
  #   appends: [{ button: boolean, label: 'string', id: 'string', display: boolean, disabled: boolean }, ...],
  #   messages: { note: 'string' }
  # ) %>
  def bootstrap_telephone_field(args = {})
    args[:html_options] = html_options(args.dig(:html_options)).merge({ minlength: 10, maxlength: 10, onkeypress: 'return /\d/.test(String.fromCharCode(((event||window.event).which||(event||window.event).which)));' })
    args[:prepends]     = [{ button: false, label: '<i class="fa fa-phone"></i>' }] + (args.dig(:prepends) || [])

    bootstrap_text_field(**args)
  end

  # <%= bootstrap_text_area(
  #   field: 'string',
  #   value: 'string',
  #   row: { class: 'string', id: 'string', display: boolean, columns: [l, r] },
  #   col: { class: 'string', id: 'string', display: boolean },
  #   form_group: { class: 'string', id: 'string', display: boolean },
  #   label: { class: 'string', id: 'string', title: 'string' },
  #   html_options: { class: 'string', id: 'string', placeholder: 'string', rows: integer, typeahead_client: Client, required: boolean, disabled: boolean, autofocus: boolean, char_count_client: Client, aiagent_prompt_count_aiagent: Aiagent },
  #   messages: { note: 'string' }
  # ) %>
  def bootstrap_text_area(args = {})
    html_options              = html_options(args.dig(:html_options))
    html_options[:id]         = "text_area_#{rand(1000)}" if html_options[:id].blank?
    html_options[:spellcheck] = true
    columns                   = columns(args.dig(:row, :columns))
    col_class                 = col_class(args.dig(:col, :class).to_s, columns)
    label_class               = label_class(args.dig(:label, :class).to_s, columns)

    response = tag.div(class: form_row_class(args.dig(:row, :class)), id: args.dig(:row, :id).to_s, style: (args.dig(:row, :display).nil? || args[:row][:display].to_bool ? '' : 'display:none;').to_s) do
      tag.label(args.dig(:label, :title).to_s, class: label_class, id: args.dig(:label, :id).to_s) +
        tag.div(class: col_class, id: args.dig(:col, :id).to_s, style: (args.dig(:col, :display).nil? || args.dig(:col, :display).to_bool ? '' : 'display:none;').to_s) do
          if args.dig(:html_options, :char_count_client).is_a?(Client) || args.dig(:html_options, :aiagent_prompt_count_aiagent).is_a?(Aiagent)
            tag.small(class: 'text-muted', style: (browser.device.mobile? ? 'font-size:60%;' : '')) do
              "(Chars: <span id=\"text_length_#{html_options[:id]}\">0</span> / Remaining: <span id=\"text_remaining_#{html_options[:id]}\">160</span> / Type: <span id=\"text_sms_type_#{html_options[:id]}\">Normal</span> / Segments: <span id=\"text_message_segments_#{html_options[:id]}\">0</span> / Cost: <span id=\"text_message_cost_#{html_options[:id]}\">0</span> credits)".html_safe
            end
          else
            token_list
          end +
            tag.div(class: (%w[publisher] + args.dig(:form_group, :class).to_s.split).join(' '), id: args.dig(:form_group, :id).to_s, style: args.dig(:form_group, :display).nil? || args.dig(:form_group, :display).to_bool ? '' : 'display:none;') do
              tag.div(class: %w[publisher-input pr-0] + (args.dig(:html_options, :typeahead_client) ? %w[has-typeahead-scrollable] : [])) do
                text_area_tag(args.dig(:field).to_sym, args.dig(:value).to_s, html_options)
              end
            end +
            tag.small(args.dig(:messages, :note).to_s, class: %w[text-muted])
        end
    end +
               tag.script("autosize($('##{html_options[:id]}'));$('##{html_options[:id]}').on('focus', function() {autosize.update($('##{html_options[:id]}'));});".html_safe)

    response += tag.script(typeahead_script(html_options[:id], args[:html_options][:typeahead_client], args[:html_options][:typeahead_drop_up].to_bool)) if args.dig(:html_options, :typeahead_client).is_a?(Client)
    response += tag.script(char_count_script(html_options[:id], client: args[:html_options][:char_count_client])) if args.dig(:html_options, :char_count_client).is_a?(Client)
    response += tag.script(aiagent_char_count_script(html_options[:id], aiagent: args[:html_options][:aiagent_prompt_count_aiagent])) if args.dig(:html_options, :aiagent_prompt_count_aiagent).is_a?(Aiagent)

    response
  end

  # <%= bootstrap_text_field(
  #   field: 'string',
  #   value: 'string',
  #   row: { class: 'string', id: 'string', display: boolean, columns: [l, r] },
  #   col: { class: 'string', id: 'string', display: boolean },
  #   form_group: { class: 'string', id: 'string', display: boolean },
  #   input_group: { class: 'string' },
  #   label: { class: 'string', id: 'string', title: 'string' },
  #   html_options: { class: 'string', id: 'string', placeholder: 'string', minlength: integer, maxlength: integer, size: integer, typeahead_client: Client, type: string, required: boolean, disabled: boolean, autofocus: boolean },
  #   prepends: [{ button: boolean, label: 'string', id: 'string', display: boolean, disabled: boolean }, ...],
  #   appends: [{ button: boolean, label: 'string', id: 'string', display: boolean, disabled: boolean, onclick: 'string' }, ...],
  #   messages: { note: 'string' },
  # ) %>
  def bootstrap_text_field(args = {})
    html_options        = html_options(args.dig(:html_options))
    html_options[:id]   = "text_field_#{rand(1000)}" if html_options[:id].blank?
    html_options[:type] = 'password' if args.dig(:html_options, :password).to_bool
    columns             = columns(args.dig(:row, :columns))
    col_class           = col_class(args.dig(:col, :class).to_s, columns)
    label_class         = label_class(args.dig(:label, :class).to_s, columns)
    prepends            = input_field_prepends(args.dig(:prepends))
    appends             = input_field_appends(args.dig(:appends))

    response = content_tag(:div, class: form_row_class(args.dig(:row, :class)), id: args.dig(:row, :id).to_s, style: (args.dig(:row, :display).nil? || args[:row][:display].to_bool ? '' : 'display:none;').to_s) do
      content_tag(:label, label_string(args.dig(:label, :title), args.dig(:messages, :note), args.dig(:html_options, :required).to_bool).html_safe, class: label_class, id: args.dig(:label, :id).to_s) +
        content_tag(:div, class: col_class, id: args.dig(:col, :id).to_s, style: (args.dig(:col, :display).nil? || args.dig(:col, :display).to_bool ? '' : 'display:none;').to_s) do
          content_tag(:div, class: (%w[form-group] + args.dig(:form_group, :class).to_s.split).join(' '), id: args.dig(:form_group, :id).to_s, style: (args.dig(:form_group, :display).nil? || args.dig(:form_group, :display).to_bool ? '' : 'display:none;').to_s) do
            content_tag(:div, class: (%w[input-group has-typeahead-scrollable flex-wrap] + (appends.present? ? %w[input-group-alt] : []) + args.dig(:input_group, :class).to_s.split)) do
              prepends.html_safe +
                text_field_tag(args.dig(:field).to_sym, args.dig(:value).to_s, html_options) +
                appends.html_safe
            end
          end
        end
    end

    response += content_tag(:script, typeahead_script(html_options[:id], args[:html_options][:typeahead_client], args[:html_options][:typeahead_drop_up].to_bool)) if args.dig(:html_options, :typeahead_client).is_a?(Client)

    response
  end

  private

  def aiagent_char_count_script(id, aiagent:)
    <<~SCRIPT.html_safe
      $(function() {
        var aiagentTextCounter = function(per_message, text) {
          var length, part_count, remaining;
          length = text.length;
          length += (text.match(/\\n/g) || []).length; // added this line to account for 1 extra character for each CRLF
          part_count = Math.ceil(length / per_message);
          remaining = length > 0 ? (per_message * part_count) - length : '&nbsp;';

          return {
            encoding: 'GSM_7BIT',
            length: length,
            per_message: per_message,
            remaining: remaining,
            part_count: part_count,
            text: text
          };
        }
        var updateTextInfo = function(e) {
          var data = aiagentTextCounter(#{Aiagent::SEGMENT_LENGTH}, $("##{id}").val());
          var length = data["length"];
          var remaining = data["remaining"];
          var part_count = data["part_count"];
          var text = data["text"];
          var per_message = data["per_message"];
          var encoding = data['encoding'];
          var sms_type = "Normal";
          var approx = text.indexOf("#") >= 0 ? "~" : ""
          var charge = (#{aiagent.credits_per_segment.to_d} * part_count);

          $('#text_length_#{id}').html(approx + length);
          $('#text_remaining_#{id}').html(approx + remaining);
          $('#text_message_segments_#{id}').html(part_count);
          // $('#text_per_message').html('Per Message: ' + per_message);
          // $('#text_encoding').html('Message Encoding: ' + encoding);
          $('#text_sms_type_#{id}').html(sms_type);
          $('#text_message_cost_#{id}').html(approx + charge);
        }
        $("##{id}").on("change keyup paste", function(e) {
          updateTextInfo(this);
        });
        updateTextInfo($("##{id}"));
      });
    SCRIPT
  end

  def calendar_script(id:, model_id:, value:, flatpickr:, google_calendar:)
    # mode options: single, multiple, range
    response = "if ('#{model_id}') {" \
               "var modalToTarget = document.getElementById('#{model_id}');" \
               '} else {' \
               'var modalToTarget = null;' \
               '}' \
               "$('##{id}').flatpickr({" \
               "altFormat: 'm/d/Y#{flatpickr.dig(:include_time).to_bool ? ' G:i K' : ''}'," \
               'allowInput: false,' \
               "dateFormat: 'm/d/Y#{flatpickr.dig(:include_time).to_bool ? ' G:i K' : ''}'," \
               "defaultDate: '#{value}'," \
               "enableTime: #{flatpickr.dig(:include_time).to_bool}," \
               "mode: '#{flatpickr.dig(:mode) || 'single'}'," \
               "minDate: '#{flatpickr.dig(:min_date)}'," \
               "maxDate: '#{flatpickr.dig(:max_date)}'," \
               'plugins: [' \
               'new confirmDatePlugin({' \
               'showAlways: true' \
               '})' \
               '],' \
               'onOpen: function(selectedDates, dateStr, instance) {' \
               'if (modalToTarget) {' \
               "modalToTarget.removeAttribute('tabindex');" \
               '}' \
               '},' \
               'onChange: function(selectedDates, dateStr, instance) {' \
               "#{flatpickr.dig(:on_change) || ''}" \
               '},' \
               'onClose: function(selectedDates, dateStr, instance) {' \
               'if (modalToTarget) {' \
               "modalToTarget.setAttribute('tabindex', -1);" \
               '}' \
               "if(selectedDates.length == 1 && '#{flatpickr.dig(:mode)}' == 'range'){" \
               'instance.setDate([selectedDates[0],selectedDates[0]], true);' \
               '}' \
               '}' \
               '});' \
               "$('#button_calendar_open_#{id}').on('click', function(e) {" \
               'setTimeout(function(){' \
               "document.querySelector('##{id}')._flatpickr.open();" \
               '}, 0);' \
               '});' \
               "$('#button_calendar_clear_#{id}').on('click', function(e) {" \
               'setTimeout(function(){' \
               "document.querySelector('##{id}')._flatpickr.clear();" \
               "document.querySelector('##{id}')._flatpickr.close();" \
               '}, 0);' \
               '});'

    if google_calendar.dig(:calendar_ids).present?
      response += "$('.google_calendar_array_#{id}').on('click', function(e) {" \
                  'e.preventDefault();' \
                  '$.ajax({' \
                  "type: 'POST'," \
                  "dataType: 'script'," \
                  "url: '#{integrations_google_integrations_path}'," \
                  'data: {' \
                  "calendar_id: $(this).data('calendar-id')," \
                  "title: '#{google_calendar.dig(:title).to_s.gsub("'") { "\\'" }}'," \
                  "description: '#{google_calendar.dig(:description).to_s.gsub("'") { "\\'" }}'," \
                  "location: '#{google_calendar.dig(:location)}'," \
                  "recurrence: '#{google_calendar.dig(:recurrence)}'," \
                  "attendee_emails: '#{google_calendar.dig(:attendee_emails)}'," \
                  "start_utc: document.querySelector('##{id}')._flatpickr.selectedDates[0]," \
                  "end_utc: document.querySelector('##{id}')._flatpickr.selectedDates[1]," \
                  "all_day: #{!flatpickr.dig(:include_time).to_bool}" \
                  '},' \
                  'success: function(result) {' \
                  'if ($.parseJSON(result)[0]) {' \
                  'ChiirpAlert({' \
                  "'body':$.parseJSON(result)[1]," \
                  "'type':'success'," \
                  "'persistent':true" \
                  '});' \
                  '} else {' \
                  'ChiirpAlert({' \
                  "'body':$.parseJSON(result)[1]," \
                  "'type':'danger'," \
                  "'persistent':true" \
                  '});' \
                  '}' \
                  '}' \
                  '});' \
                  '});'
    end

    response.html_safe
  end

  def char_count_script(id, client:)
    response = <<~SCRIPT
      $(function() {
        var updateTextInfo = function(e) {
          var text = $(e).val() || "";
          var data = SMSCounter.count(text, true);
          var length = data["length"];
          var remaining = data["remaining"];
          var part_count = data["part_count"];
          var text = data["text"];
          var per_message = data["per_message"];
          var encoding = data['encoding'];
          var sms_type = "";
          var approx = text.indexOf("#") >= 0 ? "~" : ""
          var charge = "0.00";

          if (encoding == "GSM_7BIT") {
            sms_type = "Normal";
          }else if (encoding == "GSM_7BIT_EX") {
            sms_type = "Extended"; // for 7 bit GSM: ^ { }  [ ] ~ | €
          } else if (encoding == "GSM_7BIT_EX_TR") {
            sms_type = "Turkish"; // Only for Turkish Characters "Ş ş Ğ ğ ç ı İ" encoding see https://en.wikipedia.org/wiki/GSM_03.38#Turkish_language_.28Latin_script.29
          } else if (encoding == "UTF16") {
            sms_type = "Unicode"; // for other languages "Arabic, Chinese, Russian" see http://en.wikipedia.org/wiki/GSM_03.38#UCS-2_Encoding
          }

          $('#text_length_#{id}').html(approx + length);
          $('#text_remaining_#{id}').html(approx + remaining);
          $('#text_message_segments_#{id}').html(part_count);
          // $('#text_per_message').html('Per Message: ' + per_message);
          // $('#text_encoding').html('Message Encoding: ' + encoding);
          $('#text_sms_type_#{id}').html(sms_type);

          if (#{client.unlimited ? 1 : 0} === 1) {
            // charge 0 if Client set to unlimited
            charge = '0.00';
          } else if (#{client.text_segment_charge_type.to_i} === 0) {
            // charge fixed rate for all segments
            charge = (#{client.text_message_credits.to_d} * part_count);
          } else if (#{client.text_segment_charge_type.to_i} === 1) {
            // charge graduated rate for segments
            charge = (#{client.text_message_credits.to_d} + ((part_count - 1.0) * (#{client.text_message_credits.to_d} * 0.75)));
          } else {
            // charge flat fee for action
            charge = '#{client.text_message_credits.to_d}';
          }

          $('#text_message_cost_#{id}').html(approx + charge);
          // $('#text_message_cost_currency').html('Message Cost (currency): $' + part_count * 0.00675)
        }

        $("##{id}").on("change keyup paste", function(e) {
          updateTextInfo(this);
        });
        updateTextInfo($("##{id}"));
      })
    SCRIPT
    response.html_safe
  end

  def columns(column_array)
    columns = [column_array || [3, 9]].flatten

    case columns.length
    when 2
      columns
    when 1
      [columns[0], (12 - columns[0])]
    else
      [3, 9]
    end
  end

  def col_class(col_class, columns)
    # ["col-md-#{columns[1]}", col_class, col_class.split.grep(%r{^m-}).any? || col_class.split.grep(%r{^mb-}).any? ? '' : 'mb-3'].reject(&:empty?).join(' ')
    ["col-md-#{columns[1]}", col_class].reject(&:empty?)
  end

  def dropzone_script(args = {})
    accepted_files = args.dig(:accepted_files) || UploadableMimeTypes.image_types

    return '' unless args[:javascript]

    if args.dig(:disabled).to_bool
      ''
    else
      javascript_tag(
        '$(function () {' \
        'Dropzone.autoDiscover = false;' \
        "$('##{args.dig(:drop_zone_id)}').dropzone({" \
        "url: ' '," \
        'autoQueue: false,' \
        'maxFilesize: 150,' \
        'addRemoveLinks: false,' \
        "acceptedFiles: '#{accepted_files.join(',')}'," \
        "clickable: '##{args.dig(:drop_zone_id)}, ##{args.dig(:image_container_id)}'," \
        "dragover: function() {$('##{args.dig(:drop_zone_id)}').addClass('hover');}," \
        "dragleave: function() {$('##{args.dig(:drop_zone_id)}').removeClass('hover');}," \
        "drop: function() {$('##{args.dig(:image_container_id)}').hide();$('#spinner_#{args.dig(:image_container_id)}').show();}," \
        'addedfile: function(file, response) {' \
        "$('##{args.dig(:image_container_id)}').hide();" \
        "$('#spinner_#{args.dig(:image_container_id)}').show();" \
        "const input = document.querySelector('##{args.dig(:file_field_id)}');" \
        'const url = input.dataset.directUploadUrl;' \
        'const upload = new ActiveStorage.DirectUpload(file, url);' \
        'upload.create((error, blob) => {' \
        "$.ajax({method:'PATCH',dataType:'script',url:'#{args.dig(:url)}',data:{'#{args.dig(:name)}':blob.signed_id}});" \
        '});' \
        '}' \
        '});' \
        "$('#button_image_delete_#{args.dig(:image_container_id)}').on('click', function(e) {" \
        'e.preventDefault();' \
        'e.stopPropagation();' \
        "$.ajax({type:'PATCH',dataType:'script',url:'#{args.dig(:url)}',data:{image_delete:'true'}});" \
        '});' \
        '});'
      )
    end
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

  def html_options(args)
    args ||= {}
    html_options = {}
    html_options[:autofocus]   = args[:autofocus].to_bool unless args.dig(:autofocus).nil?
    html_options[:class]       = (%w[form-control typeahead] + args.dig(:class).to_s.split).join(' ')
    html_options[:data]        = { toggle: 'selectpicker', 'selected-text-format': "count > #{(args.dig(:sp_size) || 3).to_i}", 'actions-box': args.dig(:multi_actions).nil? ? true : args[:multi_actions].to_bool, 'count-selected-text': "{0} #{args.dig(:count_selected_text) || 'items'} selected", 'live-search': args.dig(:live_search).to_bool, 'max-options': args.dig(:maxoptions) || 'false', width: 'fit', container: 'body', mobile: browser.device.mobile? }.merge(args.dig(:data) || {}) if args.dig(:select)
    html_options[:disabled]    = args[:disabled].to_bool unless args.dig(:disabled).nil?
    html_options[:id]          = (args.dig(:id) || "id_#{rand(100_000)}").to_s
    html_options[:min]         = args[:min] unless args.dig(:min).nil?
    html_options[:minlength]   = args[:minlength] unless args.dig(:minlength).nil?
    html_options[:max]         = args[:max] unless args.dig(:max).nil?
    html_options[:maxlength]   = args[:maxlength] unless args.dig(:maxlength).nil?
    html_options[:multiple]    = args[:multiple].to_bool unless args.dig(:multiple).nil?
    html_options[:onkeypress]  = args[:onkeypress] unless args.dig(:onkeypress).nil?
    html_options[:placeholder] = args[:placeholder].to_s unless args.dig(:placeholder).nil?
    html_options[:required]    = args[:required].to_bool unless args.dig(:required).nil?
    html_options[:rows]        = args[:rows].to_i unless args.dig(:rows).nil?
    html_options[:size]        = args[:size].to_i unless args.dig(:size).nil?
    html_options[:step]        = args[:step] unless args.dig(:step).nil?
    html_options[:type]        = args[:type] unless args.dig(:type).nil?
    html_options[:value]       = args[:value] unless args.dig(:value).nil?

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

  def lookup_for_select_script(args = {})
    "$('##{args.dig(:id) || "id_#{rand(100_000)}"}').selectpicker({liveSearch: true})" \
    '.ajaxSelectPicker({' \
    'ajax: {' \
    'type: \'GET\',' \
    'dataType: \'json\',' \
    "url: '#{args.dig(:lookup_url)}'," \
    'data: function () {' \
    'var params = {' \
    'searchchars: \'{{{q}}}\',' \
    "client_id: '#{args.dig(:lookup_client_id) || "id_#{rand(100_000)}"}'" \
    '};' \
    'return params;' \
    '}' \
    '},' \
    'locale: {emptyTitle: \'Search for contact...\'},' \
    'preprocessData: function(data) {' \
    'var new_contacts = [], old_contacts = [], other_contacts = [];' \
    'for (var i = 0; i < data.length; i++) {' \
    'if (data[i].new_contacts) {new_contacts.push(data[i]);}' \
    'else if (data[i].old_contacts) {old_contacts.push(data[i]);}' \
    'else {other_contacts.push(data[i]);}' \
    '}' \
    'return [].concat(new_contacts, old_contacts, other_contacts)' \
    '},' \
    'preserveSelected: false,' \
    'minLength: 3' \
    '});'.html_safe
  end

  def range_slider_script(id:, range_slider:)
    "$('##{id}').ionRangeSlider({" \
    "min: #{range_slider.dig(:min).to_i}," \
    "max: #{range_slider.dig(:max).to_i}," \
    "from: #{range_slider.dig(:from).to_i}," \
    "to: #{range_slider.dig(:to).to_i}," \
    "step: #{range_slider.dig(:step).to_i}," \
    "type: '#{range_slider.dig(:type)}'," \
    "prefix: '#{range_slider.dig(:prefix)}'," \
    "grid: #{range_slider.dig(:grid).to_bool}," \
    "grid_num: #{range_slider.dig(:grid_num).to_i}," \
    "postfix: '#{range_slider.dig(:postfix)}'," \
    "prettify_separator: '#{range_slider.dig(:separator)}'," \
    "skin: 'round'," \
    'force_edges: true,' \
    "disable: #{range_slider.dig(:disabled).to_bool}" \
    '});' \
    "window.#{range_slider.dig(:id) || "rs_#{id}_#{rand(1000)}"} = $('##{id}').data('ionRangeSlider');".html_safe
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
end
# rubocop:enable Rails/OutputSafety
