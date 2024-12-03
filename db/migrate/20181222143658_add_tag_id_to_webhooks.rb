class AddTagIdToWebhooks < ActiveRecord::Migration[5.2]
  def up
    add_reference :webhooks, :tag, index: true
  end

  def down
  	remove_reference :webhooks, :tag
  end
end
