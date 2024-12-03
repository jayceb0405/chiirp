# frozen_string_literal: true

json.id presenter.message.id
json.created_at presenter.message.created_at
json.updated_at presenter.message.updated_at
json.direction presenter.message_direction
json.folder_assignments presenter.folder_assignments
json.icon presenter.message.icon
json.color_class presenter.message_color_class
json.meta_data_html presenter.message_meta_data
json.meta_data presenter.message_meta_data_hash
json.email? presenter.message.email?
json.message presenter.message_message

json.attachments message.attachments do |attachment|
  json.id attachment.id
end

json.contact_id presenter.contact.id
