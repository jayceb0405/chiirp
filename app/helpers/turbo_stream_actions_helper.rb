# frozen_string_literal: true

# app/helpers/turbo_stream_actions_helper.rb
module TurboStreamActionsHelper
  def append_class(elements, new_class)
    if elements[0] == '.'
      turbo_stream_action_tag :append_class, targets: elements, new_class:
    else
      turbo_stream_action_tag :append_class, target: elements, new_class:
    end
  end

  def bootstrap_init
    turbo_stream_action_tag :bootstrap_init
  end

  def collapse_hide(elements)
    if elements[0] == '.'
      turbo_stream_action_tag :collapse_hide, targets: elements
    else
      turbo_stream_action_tag :collapse_hide, target: elements
    end
  end

  def collapse_show(elements)
    if elements[0] == '.'
      turbo_stream_action_tag :collapse_show, targets: elements
    else
      turbo_stream_action_tag :collapse_show, target: elements
    end
  end

  def collapse_toggle(elements)
    if elements[0] == '.'
      turbo_stream_action_tag :collapse_toggle, targets: elements
    else
      turbo_stream_action_tag :collapse_toggle, target: elements
    end
  end

  def console_log(message)
    turbo_stream_action_tag :console_log, message:
  end

  def hide(target)
    turbo_stream_action_tag :hide, target:
  end

  def hide_modal(target)
    turbo_stream_action_tag :hide_modal, target:
  end

  def redirect_to(location)
    turbo_stream_action_tag :redirect_to, location:
  end

  def remove_class(elements, old_class)
    if elements[0] == '.'
      turbo_stream_action_tag :remove_class, targets: elements, old_class:
    else
      turbo_stream_action_tag :remove_class, target: elements, old_class:
    end
  end

  def rotate_button(elements)
    if elements[0] == '.'
      turbo_stream_action_tag :rotate_button, targets: elements
    else
      turbo_stream_action_tag :rotate_button, target: elements
    end
  end

  def rotate_button_closed(elements)
    if elements[0] == '.'
      turbo_stream_action_tag :rotate_button_closed, targets: elements
    else
      turbo_stream_action_tag :rotate_button_closed, target: elements
    end
  end

  def rotate_button_open(elements)
    if elements[0] == '.'
      turbo_stream_action_tag :rotate_button_open, targets: elements
    else
      turbo_stream_action_tag :rotate_button_open, target: elements
    end
  end

  def show_modal(target)
    turbo_stream_action_tag :show_modal, target:
  end

  def show(target)
    turbo_stream_action_tag :show, target:
  end

  def toast(type, body: '', subject: '', timeout: 0, extendedtimeout: 0)
    turbo_stream_action_tag :toast, type:, body:, subject:, timeout:, extendedtimeout:
  end
end

Turbo::Streams::TagBuilder.prepend(TurboStreamActionsHelper)
