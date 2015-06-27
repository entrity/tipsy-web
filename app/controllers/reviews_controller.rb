class ReviewsController < ApplicationController
  respond_to :json, :html

  before_action :authenticate_user!

  def count
    render text:Review.count
  end

  def index
    respond_with Review.limit(10)
  end

  def show
    respond_with Review.find(params[:id])
  end

  def vote
    coefficient = params[:coefficient].to_i
    if coefficient.abs > 1
      render status: 422, json:{errors:['Coefficient must be between -1 and 1.']}
    end
    points = current_user.log_points * coefficient
    @review = Review.find(params[:id])
    @vote = ReviewVote.create(review:@review, user:current_user, points:points)
    respond_with @vote
  end

end
