class AddResponseToWebhookMaps < ActiveRecord::Migration[5.2]
  def up
    add_column :webhook_maps, :response, :text

    WebhookMap.where(internal_key: "ok2text").update_all(internal_key: "yesno")
  end

  def down
    remove_column :webhook_maps, :response

    WebhookMap.where(internal_key: "yesno").update_all(internal_key: "ok2text")
  end
end
