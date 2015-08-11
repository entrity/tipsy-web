class CommentsController < ApplicationController
  before_filter :require_signed_in

  respond_to :json

  def create
    @comment = Comment.new comment_params
    @comment.set_user(current_user)
    @comment.status = Flaggable::APPROVED
    if @comment.save
      current_user.increment_comment_ct!
    end
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

  def unvote_tip
    respond_with CommentTipVote.where(user_id:current_user.id, comment_id:params[:id]).first.destroy
  end

  def vote_tip
    attrs = {user_id:current_user.id, comment_id:params[:id]}
    @vote = CommentTipVote.new(attrs)
    respond_with @vote.save ? @vote : (CommentTipVote.where(attrs).first || @vote)
  end

  private

    def comment_params
      params.permit([
        :drink_id,
        :text,
        :parent_id,
      ])
    end

    def comment_tip_vote_url comment_vote_tip
      ''
    end

    def comment_tip_votes_url
      ''
    end

end
