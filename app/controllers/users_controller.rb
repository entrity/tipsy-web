class UsersController < ApplicationController
  respond_to :json

  before_action :require_signed_in, only: :unviewed_point_distributions

  def show
    if params[:id]
      if params[:id] =~ /\d+/
        @user = params[:id].to_i == 0 ? current_user : User.find(params[:id])
      else
        @user = User.find_by_nickname(params[:id])
      end
    end
    respond_with @user
  end

  def unviewed_point_distributions
    @point_distributions = PointDistribution.where(user_id: current_user.id, viewed: false)
    respond_with @point_distributions.as_json
  end

  def viewed_point_distributions
    @updates = PointDistribution.where(user_id: current_user.id, id:params[:id]).update_all(viewed: true)
    respond_with @updates
  end

end
