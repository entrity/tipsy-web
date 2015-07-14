class ReviewsController < ApplicationController
  respond_to :json, :html

  before_action :authenticate_user!

  def count
    render text:Review.open(current_user).limit(51).count
  end

  def index
    respond_with Review.limit(10)
  end

  def next
    @review = Review.next!(current_user)
    if @review
      respond_with @review.as_json(methods: [:reviewable])
    else
      respond_with nil, status: 423
    end
  end

  def vote
    coefficient = params[:coefficient].to_i
    if coefficient.abs > 1
      render status: 422, json:{errors:['Coefficient must be between -1 and 1.']}
    end
    points = current_user.log_points * coefficient
    @review = Review.find(params[:id])
    # after_create callback will add/set user & points & openness to @review
    @vote = ReviewVote.create(review:@review, user:current_user, points:points)
    if @vote.invalid?
      # In case of data error in Review, correct the data
      if !@vote.unique?
        @review.flagger_ids << current_user.id
        @review.save!
      end
      # Copy errors, if any, from @vote to @review
      @vote.errors.messages.each do |field, array|
        array.each do |value|
          @review.errors.add(field, value)
        end
      end
    end
    respond_with @review
  end

end
