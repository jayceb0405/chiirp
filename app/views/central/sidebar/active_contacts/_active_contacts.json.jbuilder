# frozen_string_literal: true

# app/views/central/sidebar/active_contacts/_active_contacts.html.erb
#
# Example:
#   render partial: 'central/sidebar/active_contacts/active_contacts', locals: { presenter: CentralPresenter }
#
# Instance Variables:
#   none
#
# Local Variables:
#   (req) presenter: (CentralPresenter)
#
return unless local_assigns.dig(:presenter).is_a?(CentralPresenter)

json.page presenter.active_contacts_list.current_page.to_i
json.messages presenter.active_contacts_list do |contact|
  json.message do
    json.id contact.tw_id
    json.message contact.tw_message
    json.msg_type contact.tw_msg_type
    json.created_at contact.tw_created_at
  end

  json.contact_id contact.id
  json.fullname_or_phone presenter.contact.fullname_or_phone
  json.user_client_tag presenter.user_client_tag
  json.user_typing_id presenter.user_typing&.id
end
