class RevisionsController < ApplicationController
  before_filter :require_signed_in

  respond_to :json

  def create
    @model = controller_path.classify.constantize
    @revision = @model.new revision_params
    @revision.user = current_user
    @revision.status = Flaggable::NEEDS_REVIEW
    if @revision.save
      Review.create! reviewable:@revision, contributor:current_user
    end
    respond_with @revision
  end

  private

    def revision_params
      params.permit(
        :drink_id,
        :parent_id,
        :base_id,
        {:ingredients => DrinkIngredient.column_names},
        {:prev_ingredients => DrinkIngredient.column_names},
        :description,
        :prev_description,
        :instructions,
        :prev_instruction,
        :non_alcoholic,
        :profane,
        :prep_time,
        :calories,
        :name,
      )
    end
end
