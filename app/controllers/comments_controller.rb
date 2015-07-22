class CommentsController < ApplicationController
  before_filter :require_signed_in

  respond_to :json

  def create
    @comment = Comment.new comment_params
    @comment.set_user(current_user)
    @comment.status = Flaggable::APPROVED
    @comment.save
    respond_with @comment
  end

  def destroy
    @comment = Comment.find params[:id]
    if @comment.user_id == current_user.id
      @comment.destroy
      respond_with @comment
    else
      render nothing:true, status:403
    end
  end

  private

    def comment_params
      params.permit([
        :drink_id,
        :text,
        :parent_id,
      ])
    end

end
