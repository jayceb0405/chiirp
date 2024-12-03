# frozen_string_literal: true

# app/models/users/dashboards/message.rb
module Users
  module Dashboards
    class Message
      # number of Contacts who were sent a text message
      #   (req) user_settings: (Users::Setting)
      def messages_contacts_messaged(user_settings)
        date_range     = Users::Dashboards::Dashboard.new.date_range(user_settings)
        messages       = if user_settings.data.dig(:user_ids).present?
                           Messages::Message.texts_sent_by_user(user_settings.data[:user_ids], date_range[0], date_range[1]).pluck(:contact_id, :created_at)
                         else
                           Messages::Message.texts_sent_by_client(user_settings.user.client_id, date_range[0], date_range[1]).pluck(:contact_id, :created_at)
                         end
        period_lengths = period_lengths(date_range)

        {
          value:     messages.map { |m| m[0] }.uniq.count,
          sparkline: {
            point_1: messages.select { |m| m[1].between?(date_range[0], period_lengths[0]) }.map { |m| m[0] }.uniq.count,
            point_2: messages.select { |m| m[1].between?(period_lengths[0], period_lengths[1]) }.map { |m| m[0] }.uniq.count,
            point_3: messages.select { |m| m[1].between?(period_lengths[1], period_lengths[2]) }.map { |m| m[0] }.uniq.count,
            point_4: messages.select { |m| m[1].between?(period_lengths[2], date_range[1]) }.map { |m| m[0] }.uniq.count
          }
        }
      end

      # average response time for incoming text messages
      #   (req) user_settings: (Users::Setting)
      def messages_team_response_time(user_settings)
        date_range     = Users::Dashboards::Dashboard.new.date_range(user_settings)
        texts_in       = texts_in(date_range[0], date_range[1], user_settings.user.client, user_settings.data.dig(:user_ids))
        texts_out      = texts_out(date_range[0], user_settings.user.client, texts_in)
        period_lengths = period_lengths(date_range)

        {
          value:     (texts_out_avg(texts_in, texts_out) / 60).round(2),
          sparkline: {
            point_1: (texts_out_avg(texts_in.select { |m| m.created_at.between?(date_range[0], period_lengths[0]) }, texts_out) / 60).round(2),
            point_2: (texts_out_avg(texts_in.select { |m| m.created_at.between?(period_lengths[0], period_lengths[1]) }, texts_out) / 60).round(2),
            point_3: (texts_out_avg(texts_in.select { |m| m.created_at.between?(period_lengths[1], period_lengths[2]) }, texts_out) / 60).round(2),
            point_4: (texts_out_avg(texts_in.select { |m| m.created_at.between?(period_lengths[2], date_range[1]) }, texts_out) / 60).round(2)
          }
        }
      end

      # text messages delivered by carriers
      # (req) user_settings: (Users::Setting)
      def messages_delivery_rate(user_settings)
        date_range            = Users::Dashboards::Dashboard.new.date_range(user_settings)
        messages_sent         = if user_settings.data.dig(:user_ids).present?
                                  Messages::Message.texts_sent_by_user(user_settings.data[:user_ids], date_range[0], date_range[1]).pluck(:created_at)
                                else
                                  Messages::Message.texts_sent_by_client(user_settings.user.client_id, date_range[0], date_range[1]).pluck(:created_at)
                                end
        messages_delivered    = if user_settings.data.dig(:user_ids).present?
                                  Messages::Message.texts_delivered_by_user(user_settings.data.dig(:user_ids), date_range[0], date_range[1]).pluck(:created_at)
                                else
                                  Messages::Message.texts_delivered_by_client(user_settings.user.client_id, date_range[0], date_range[1]).pluck(:created_at)
                                end
        period_lengths        = period_lengths(date_range)
        point_1_message_count = messages_sent.select { |m| m.between?(date_range[0], period_lengths[0]) }.count.to_d
        point_2_message_count = messages_sent.select { |m| m.between?(period_lengths[0], period_lengths[1]) }.count.to_d
        point_3_message_count = messages_sent.select { |m| m.between?(period_lengths[1], period_lengths[2]) }.count.to_d
        point_4_message_count = messages_sent.select { |m| m.between?(period_lengths[2], date_range[1]) }.count.to_d

        {
          value:     (messages_delivered.count.to_d / messages_sent.count.to_d).round(2).to_f,
          sparkline: {
            point_1: point_1_message_count.zero? ? 0.0 : (messages_delivered.select { |m| m.between?(date_range[0], period_lengths[0]) }.count.to_d / point_1_message_count).round(2).to_f,
            point_2: point_2_message_count.zero? ? 0.0 : (messages_delivered.select { |m| m.between?(period_lengths[0], period_lengths[1]) }.count.to_d / point_2_message_count).round(2).to_f,
            point_3: point_3_message_count.zero? ? 0.0 : (messages_delivered.select { |m| m.between?(period_lengths[1], period_lengths[2]) }.count.to_d / point_3_message_count).round(2).to_f,
            point_4: point_4_message_count.zero? ? 0.0 : (messages_delivered.select { |m| m.between?(period_lengths[2], date_range[1]) }.count.to_d / point_4_message_count).round(2).to_f
          }
        }
      end

      def period_lengths(date_range)
        period_length = (date_range[1] - date_range[0]).round(0)
        period_1 = date_range[0] + (period_length / 4)
        period_2 = period_1 + (period_length / 4)
        period_3 = period_2 + (period_length / 4)

        [period_1, period_2, period_3]
      end

      def average_text_response_time(start_time, end_time, client, user_ids)
        texts_in = texts_in(start_time, end_time, client, user_ids)
        texts_out = texts_out(start_time, client, texts_in)

        texts_out_avg(texts_in, texts_out)
      end

      def maximum_text_response_time(start_time, end_time, client, user_ids)
        texts_in = texts_in(start_time, end_time, client, user_ids)
        texts_out = texts_out(start_time, client, texts_in)

        texts_out_max(texts_in, texts_out)
      end

      def minimum_text_response_time(start_time, end_time, client, user_ids)
        texts_in = texts_in(start_time, end_time, client, user_ids)
        texts_out = texts_out(start_time, client, texts_in)

        texts_out_min(texts_in, texts_out)
      end

      # get the texts received by a client or user within a specified period of time
      #   (req) start_time: (Time)
      #   (req) end_time:   (Time)
      #   (req) client:     (Client)
      #   (req) user_ids:   (Array)
      def texts_in(start_time, end_time, client, user_ids)
        if user_ids.present?
          Messages::Message.texts_received_by_user(user_ids, start_time, end_time).select('contact_id, MAX(messages.created_at) AS created_at').group(:contact_id)
        else
          Messages::Message.texts_received_by_client(client.id, start_time, end_time).select('contact_id, MAX(messages.created_at) AS created_at').group(:contact_id)
        end
      end

      def texts_out(start_time, client, texts_in)
        texts_out = client.messages.where(msg_type: Messages::Message::MSG_TYPES_TEXTOUT, created_at: start_time..Time.current, contact_id: texts_in.map(&:contact_id)).select('contact_id, messages.created_at AS created_at').order(:contact_id, :created_at)
        texts_out = texts_out.to_a.delete_if { |text_out| text_out.created_at < texts_in.find { |text_in| text_in.contact_id == text_out.contact_id }.created_at }
        texts_out.map { |t| t.contact_id }.uniq.each do |contact_id|
          texts_out.delete_if { |tt| tt != texts_out.find { |ttt| ttt.contact_id == contact_id } }
        end

        texts_out
      end

      def texts_out_avg(texts_in, texts_out)
        response = texts_in.length.zero? ? [] : texts_in.map { |text_in| texts_out.find { |text_out| text_out.contact_id == text_in.contact_id }&.created_at&.- text_in.created_at }.compact_blank
        response.blank? ? 0.0 : (response.sum / response.length.to_f).round(2)
      end

      def texts_out_max(texts_in, texts_out)
        texts_in.map { |text_in| (texts_out.find { |text_out| text_out.contact_id == text_in.contact_id }&.created_at&.- text_in.created_at) }.compact_blank.max.to_f.round(2)
      end

      def texts_out_min(texts_in, texts_out)
        texts_in.map { |text_in| (texts_out.find { |text_out| text_out.contact_id == text_in.contact_id }&.created_at&.- text_in.created_at) }.compact_blank.min.to_f.round(2)
      end
    end
  end
end
