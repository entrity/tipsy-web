class RevisionsController < ApplicationController
  respond_to :json

  def create
    @revision = Revision.new revision_params
    @revision.user = current_user
    @revision.status = Flaggable::NEEDS_REVIEW
    if @revision.save
      Review.create! reviewable:@revision
    end
    respond_with @revision
  end

  private

    def revision_params
      params.permit(:drink_id, :parent_id, :ingredients, :description, :instructions, :non_alcoholic, :profane, :prep_time, :calories, :name)
    end
end
