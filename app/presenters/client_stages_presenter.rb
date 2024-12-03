# frozen_string_literal: true

# app/presenters/client_stages_presenter.rb
class ClientStagesPresenter
  attr_reader :stage, :stage_parent

  def initialize(args = {})
    if args.dig(:stage)
      self.stage        = args.dig(:stage)
      self.stage_parent = args.dig(:stage_parent)
    else
      self.stage_parent = args.dig(:stage_parent)
      self.stage        = args.dig(:stage)
    end
  end

  def stage=(stage)
    @stage = if stage.is_a?(Stage)
               stage
             elsif stage.is_a?(Integer)
               Stage.find_by(id: stage)
             elsif self.stage_parent.is_a?(StageParent)
               self.stage_parent.stages.new
             else
               Stage.new
             end
  end

  def stage_parent=(stage_parent)
    @stage_parent = if stage_parent.is_a?(StageParent)
                      stage_parent
                    elsif stage_parent.is_a?(Integer)
                      StageParent.find_by(id: stage_parent)
                    elsif self.stage.is_a?(Stage)
                      self.stage.stage_parent
                    else
                      StageParent.new
                    end
  end

  def stages
    self.stage_parent.stages.includes(:contacts, :campaign).order(:sort_order)
  end
end
