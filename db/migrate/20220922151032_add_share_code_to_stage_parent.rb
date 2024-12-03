class AddShareCodeToStageParent < ActiveRecord::Migration[7.0]
  def change
    ActiveRecord::Base.record_timestamps = false
    say 'Turned off timestamps.'

    say_with_time 'Adding "share_code" to StageParent table...' do
      add_column :stage_parents, :share_code, :string, default: '', null: false, index: true
    end

    ActiveRecord::Base.record_timestamps = true
    say 'Turned on timestamps.'
  end
end

# Run in console after deploy
# ActiveRecord::Base.record_timestamps = false
# StageParent.find_each do |stage_parent|
#   stage_parent.share_code = RandomCode.new.create(20)
#   stage_parent.share_code = RandomCode.new.create(20) while StageParent.find_by(share_code: stage_parent.share_code)
#   stage_parent.save
# end

# Client.find_each do |client|
#   client.share_stages_allowed = client.stages_count.to_i.positive?
#   client.save
# end

# Package.find_each do |package|
#   package.share_stages_allowed = package.stages_count.to_i.positive?
#   package.save
# end
