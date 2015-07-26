class VotesController < ApplicationController
  respond_to :json

  before_action :require_signed_in, only: :create

  # Create or update a vote
  def create
    @vote = Vote.new vote_params
    @vote.user = current_user
    @vote.save
    respond_with @vote
  end

  private

    def vote_params
      params.permit(:votable_id, :votable_type, :sign, :user_id)
    end

end
