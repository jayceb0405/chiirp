class AddHelpGcstToAiagents < ActiveRecord::Migration[7.0]
  def change
    change_table :aiagents do |t|
      t.belongs_to :help_campaign,            foreign_key: { to_table: :campaigns }
      t.belongs_to :help_group,               foreign_key: { to_table: :groups }
      t.belongs_to :help_tag,                 foreign_key: { to_table: :tags }
      t.belongs_to :help_stage,               foreign_key: { to_table: :stages }
    end
  end
end
