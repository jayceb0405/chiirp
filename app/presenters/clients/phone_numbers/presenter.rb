# frozen_string_literal: true

# app/presenters/clients/phone_numbers/presenter.rb
module Clients
  module PhoneNumbers
    class Presenter < BasePresenter
      attr_accessor :twnumber

      # presenter = local_assigns.dig(:presenter) || Clients::PhoneNumbers::Presenter.new(client: @client)

      def client=(client)
        super
        @twnumber = nil
      end

      def ok_to_purchase_new_number?
        self.twnumbers.count < self.client.current_max_phone_numbers
      end

      def options_for_def_phone_user
        @client.users.where(id: @twnumber&.twnumberusers&.pluck(:user_id))&.order(:lastname, :firstname)&.pluck(:id, :firstname, :lastname)&.map { |user| [Friendly.new.fullname(user[1], user[2]), user[0]] }
      end

      def options_for_phone_users
        @client.users.order(:lastname, :firstname).pluck(:id, :firstname, :lastname).map { |user| [Friendly.new.fullname(user[1], user[2]), user[0]] }
      end

      def options_for_twnumber_pass_routing
        response = [['Route to User Assigned to Contact', 'def_user']]
        response += @client.users.collect { |u| ["Route to #{u.fullname}", u.id] }
        response += [['Route to Phone Number', 'phone_number']]

        response
      end

      def pass_routing_selected
        response = []
        users = @client.users.where(id: @twnumber&.pass_routing).to_h { |u| [u.id.to_s, u.fullname] }

        @twnumber&.pass_routing&.each do |r|
          response << case r
                      when 'def_user'
                        ['User Assigned to Contact', 'def_user']
                      when 'phone_number'
                        ['Phone Number', 'phone_number']
                      else
                        [users[r], r] if users.key?(r)
                      end
        end

        response.compact_blank
      end

      def radio_buttons_incoming_call_routing
        buttons = []
        buttons << { label: 'Play announcement and wait for voicemail', value: 'play_vm', id: "incoming_call_routing_play_vm_#{@twnumber&.id}", class: "incoming_call_routing_radio_#{@twnumber&.id}", checked: @twnumber&.incoming_call_routing == 'play_vm' }
        buttons << { label: 'Play announcement and hang up (no voicemail)', value: 'play', id: "incoming_call_routing_play_#{@twnumber&.id}", class: "incoming_call_routing_radio_#{@twnumber&.id}", checked: @twnumber&.incoming_call_routing == 'play' }
        buttons << { label: 'Play announcement and pass through to User', value: 'play_pass', id: "incoming_call_routing_play_pass_#{@twnumber&.id}", class: "incoming_call_routing_radio_#{@twnumber&.id}", checked: @twnumber&.incoming_call_routing == 'play_pass' }
        buttons << { label: 'Pass through to User', value: 'pass', id: "incoming_call_routing_pass_#{@twnumber&.id}", class: "incoming_call_routing_radio_#{@twnumber&.id}", checked: @twnumber&.incoming_call_routing == 'pass' }
      end

      def radio_buttons_pass_routing_method
        buttons = []
        buttons << { label: 'Multi-number <small>(ring all numbers simultaneously)</small>'.html_safe, value: 'multi', id: "pass_routing_method_multi_#{@twnumber&.id}", class: "pass_routing_method_radio_#{@twnumber&.id}", checked: @twnumber&.pass_routing_method == 'multi' }
        buttons << { label: 'Chained-number <small>(ring each number in succession until the call is answered)</small>'.html_safe, value: 'chain', id: "pass_routing_method_chained_#{@twnumber&.id}", class: "pass_routing_method_radio_#{@twnumber&.id}", checked: @twnumber&.pass_routing_method == 'chain' }
      end

      def twnumber_def_user
        @twnumber&.twnumberusers&.find_by(def_user: true)&.user_id.to_i
      end

      def twnumber_users
        @twnumber&.users&.pluck(:id) || []
      end

      def twnumbers
        @client.twnumbers.order(:name, :phonenumber)
      end
    end
  end
end
