class RevisionsController < ApplicationController
  respond_to :json

  def create
    @revision = Revision.new revision_params
    @revision.user = current_user
    @revision.status = @revision.publishable_without_review? ? Flaggable::APPROVED : Flaggable::NEEDS_REVIEW
    if @revision.save && !@revision.publishable_without_review?
      Review.create! reviewable:@revision
    end
    respond_with @revision
  end

  private

    def revision_params
      params.require(:flaggable_id, :flaggable_type, :text)
    end
end
