# frozen_string_literal: true

# app/helpers/messages/message_helper.rb
module Messages
  # helpers specific to Users
  module MessageHelper
    def message_color_class(msg_type, automated = false, aiagent = false)
      case msg_type
      when 'textin'
        'color_is_textin'
      when 'textout'
        if automated
          aiagent ? 'color_is_textoutaiagent' : 'color_is_textout_automated'
        else
          'color_is_textout'
        end
      when 'textinuser'
        'color_is_textinuser'
      when 'textoutuser'
        'color_is_textoutuser'
      when 'textoutaiagent'
        'color_is_textoutaiagent'
      when 'textinother'
        'color_is_textinother'
      when 'textoutother'
        'color_is_textoutother'
      when 'emailout'
        'color_is_emailout'
      when 'emailin'
        'color_is_emailin'
      when 'fbin'
        'color_is_fbin'
      when 'fbout'
        if automated
          'color_is_fbout_automated'
        else
          'color_is_fbout'
        end
      when 'gglin'
        'color_is_gglin'
      when 'gglout'
        if automated
          'color_is_gglout_automated'
        else
          'color_is_gglout'
        end
      when 'rvmout'
        'color_is_rvmout'
      when 'voicein'
        'color_is_voicein'
      when 'voiceout'
        'color_is_voiceout'
      when 'voicemail'
        'color_is_voicemail'
      when 'widgetin'
        'color_is_widgetin'
      when 'video'
        'color_is_video'
      else
        'color_is_unknown'
      end
    end
  end
end
